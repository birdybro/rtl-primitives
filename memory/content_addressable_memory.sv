// =============================================================================
// Module: content_addressable_memory
// Description:
//   Fully-associative Content Addressable Memory (CAM).  Each entry stores a
//   data word and a valid bit.  A combinational search compares the search_key
//   against all valid entries in parallel and returns the address (index) of
//   the first matching entry along with a hit flag.  Entries are written
//   (including their valid bit) synchronously.
//
//   When multiple entries match the key the lowest-index matching entry wins
//   (priority encoder selects the LSB match).
//
// Parameters:
//   DATA_WIDTH - Width of each CAM data word / search key in bits (default: 8)
//   DEPTH      - Number of CAM entries (default: 16)
//
// Ports:
//   clk         - System clock (rising-edge triggered)
//   rst_n       - Asynchronous active-low reset (clears all valid bits)
//   wr_en       - Write enable; stores wr_data and wr_valid_bit at wr_addr
//   wr_addr     - Address of the entry to write
//   wr_data     - Data word to store at wr_addr
//   wr_valid_bit- Valid bit to associate with the written entry
//   search_key  - Key to search for across all valid entries
//   hit         - Combinational output; high when search_key matches any entry
//   hit_addr    - Combinational output; address of the first (lowest) match
//
// Timing / Behaviour:
//   - Writes are synchronous (registered on the rising edge of clk).
//   - Search (hit, hit_addr) is purely combinational; result is available
//     within the same clock cycle that search_key is presented.
//   - Valid bits are cleared by reset; data array is not reset.
//   - If no entry matches, hit is low and hit_addr is undefined (driven to 0).
//
// Usage Notes:
//   - To invalidate an entry, write with wr_valid_bit = 0.
//   - DEPTH should be small (≤ 64) for practical synthesis; large CAMs are
//     expensive in FPGA/ASIC resources.
//
// Example Instantiation:
//   content_addressable_memory #(
//     .DATA_WIDTH(8),
//     .DEPTH     (16)
//   ) u_cam (
//     .clk         (clk),
//     .rst_n       (rst_n),
//     .wr_en       (wr_en),
//     .wr_addr     (wr_addr),
//     .wr_data     (wr_data),
//     .wr_valid_bit(wr_valid_bit),
//     .search_key  (search_key),
//     .hit         (hit),
//     .hit_addr    (hit_addr)
//   );
// =============================================================================

module content_addressable_memory #(
    parameter int DATA_WIDTH = 8,
    parameter int DEPTH      = 16
) (
    input  logic                          clk,
    input  logic                          rst_n,

    // Write interface
    input  logic                          wr_en,
    input  logic [$clog2(DEPTH)-1:0]      wr_addr,
    input  logic [DATA_WIDTH-1:0]         wr_data,
    input  logic                          wr_valid_bit,

    // Search interface (combinational)
    input  logic [DATA_WIDTH-1:0]         search_key,
    output logic                          hit,
    output logic [$clog2(DEPTH)-1:0]      hit_addr
);

    // Storage
    logic [DATA_WIDTH-1:0] cam_data  [0:DEPTH-1];
    logic                  cam_valid [0:DEPTH-1];

    // Per-entry match vector: valid and data equal search_key
    logic [DEPTH-1:0] match;

    // Synchronous write of data and valid bit; reset clears valid bits only
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < DEPTH; i++)
                cam_valid[i] <= 1'b0;
        end else if (wr_en) begin
            cam_data [wr_addr] <= wr_data;
            cam_valid[wr_addr] <= wr_valid_bit;
        end
    end

    // Combinational match generation
    always_comb begin
        for (int i = 0; i < DEPTH; i++)
            match[i] = cam_valid[i] && (cam_data[i] == search_key);
    end

    // Priority encoder: select the lowest-index match
    always_comb begin
        hit      = |match;
        hit_addr = '0;
        for (int i = DEPTH-1; i >= 0; i--) begin
            if (match[i])
                hit_addr = ($clog2(DEPTH))'(i);
        end
    end

endmodule
