// =============================================================================
// Module: line_buffer
// Description:
//   Streaming line buffer designed for image/video processing pipelines.
//   Incoming pixels are written sequentially into a set of NUM_LINES shift
//   registers, each LINE_WIDTH pixels deep.  At every write clock edge a
//   vertical column of NUM_LINES pixels (one from each line) is presented on
//   line_out, along with the current column index on pixel_col.
//
//   Internal organisation (example: NUM_LINES=3, LINE_WIDTH=8):
//
//     line[2]: [ p0 | p1 | p2 | ... | p7 ]   (oldest line)
//     line[1]: [ p0 | p1 | p2 | ... | p7 ]
//     line[0]: [ p0 | p1 | p2 | ... | p7 ]   (newest partial line)
//              ^--- col 0 is the leftmost (oldest) pixel in the active line
//
//   After LINE_WIDTH pixels have been received the write pointer wraps to 0
//   and the lines shift: what was line[0] becomes line[1], etc.
//
// Parameters:
//   DATA_WIDTH - Bit-width of each pixel (default: 8)
//   LINE_WIDTH - Number of pixels per line / row (default: 8)
//   NUM_LINES  - Number of lines retained (default: 3; depth of the column)
//
// Ports:
//   clk       - System clock (rising-edge triggered)
//   rst_n     - Asynchronous active-low reset
//   wr_en     - Write enable; accepts one pixel per asserted cycle
//   wr_data   - Incoming pixel value
//   pixel_col - Registered column index of the pixel most recently written
//   line_out  - Column of NUM_LINES pixels at pixel_col; [0] = newest line
//   line_valid- Asserted once NUM_LINES full lines have been buffered
//
// Timing / Behaviour:
//   - pixel_col and line_out update on the clock edge after wr_en is sampled.
//   - line_valid is a registered signal that goes high after NUM_LINES complete
//     lines have been written and remains high thereafter (not self-clearing).
//   - Reset clears pointers, valid flag, and the entire pixel store.
//
// Usage Notes:
//   - Consume line_out only when line_valid is high.
//   - For a 3-line buffer driving a 3×1 convolution kernel, wire line_out[2],
//     line_out[1], line_out[0] to the top, middle, and bottom tap inputs.
//   - wr_en must be held low between frames (or the module can be reset) to
//     avoid contaminating the buffer with stale pixels from a previous frame.
//
// Example Instantiation:
//   line_buffer #(
//     .DATA_WIDTH(8),
//     .LINE_WIDTH(640),
//     .NUM_LINES (3)
//   ) u_lbuf (
//     .clk      (clk),
//     .rst_n    (rst_n),
//     .wr_en    (wr_en),
//     .wr_data  (wr_data),
//     .pixel_col(pixel_col),
//     .line_out (line_out),
//     .line_valid(line_valid)
//   );
// =============================================================================

module line_buffer #(
    parameter int DATA_WIDTH = 8,
    parameter int LINE_WIDTH = 8,
    parameter int NUM_LINES  = 3
) (
    input  logic                                   clk,
    input  logic                                   rst_n,

    input  logic                                   wr_en,
    input  logic [DATA_WIDTH-1:0]                  wr_data,

    output logic [$clog2(LINE_WIDTH)-1:0]          pixel_col,
    output logic [NUM_LINES-1:0][DATA_WIDTH-1:0]   line_out,
    output logic                                   line_valid
);

    // Pixel storage: NUM_LINES rows, each LINE_WIDTH pixels wide
    logic [DATA_WIDTH-1:0] buf_mem [0:NUM_LINES-1][0:LINE_WIDTH-1];

    // Write-column pointer (position within the current line being filled)
    logic [$clog2(LINE_WIDTH)-1:0] col_ptr;

    // Count of complete lines written so far (saturates at NUM_LINES)
    logic [$clog2(NUM_LINES+1)-1:0] lines_filled;

    // Detect wrap at end of a line
    wire last_col = (col_ptr == LINE_WIDTH[$clog2(LINE_WIDTH)-1:0] - 1'b1);

    // Write logic: incoming pixel fills the newest (index 0) row at col_ptr.
    // At the end of a line, all rows shift up (oldest is discarded) and the
    // newest row starts filling from column 0 again.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            col_ptr      <= '0;
            lines_filled <= '0;
            for (int r = 0; r < NUM_LINES; r++)
                for (int c = 0; c < LINE_WIDTH; c++)
                    buf_mem[r][c] <= '0;
        end else if (wr_en) begin
            // Store pixel into the newest line
            buf_mem[0][col_ptr] <= wr_data;

            if (last_col) begin
                col_ptr <= '0;

                // Shift lines: buf_mem[1] <- buf_mem[0], [2] <- [1], etc.
                for (int r = NUM_LINES-1; r > 0; r--)
                    for (int c = 0; c < LINE_WIDTH; c++)
                        buf_mem[r][c] <= buf_mem[r-1][c];

                if (lines_filled < NUM_LINES[$clog2(NUM_LINES+1)-1:0])
                    lines_filled <= lines_filled + 1'b1;
            end else begin
                col_ptr <= col_ptr + 1'b1;
            end
        end
    end

    // Registered outputs
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pixel_col  <= '0;
            line_valid <= 1'b0;
            for (int r = 0; r < NUM_LINES; r++)
                line_out[r] <= '0;
        end else if (wr_en) begin
            pixel_col  <= col_ptr;
            line_valid <= (lines_filled >= (NUM_LINES - 1));
            for (int r = 0; r < NUM_LINES; r++)
                line_out[r] <= buf_mem[r][col_ptr];
        end
    end

endmodule
