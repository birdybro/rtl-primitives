`timescale 1ns/1ps
module async_fifo_tb;
  parameter int DW = 8, AW = 4;
  localparam int DEPTH = 1 << AW;

  logic wr_clk, wr_rst_n, wr_en, wr_full;
  logic [DW-1:0] wr_data;
  logic rd_clk, rd_rst_n, rd_en, rd_empty;
  logic [DW-1:0] rd_data;
  int pass_cnt = 0, fail_cnt = 0;

  async_fifo #(.DATA_WIDTH(DW), .ADDR_WIDTH(AW)) dut (.*);

  initial wr_clk = 0; always #5  wr_clk = ~wr_clk;  // 100 MHz
  initial rd_clk = 0; always #8  rd_clk = ~rd_clk;  //  62 MHz

  // Write task
  task automatic write_word(input logic [DW-1:0] val);
    @(posedge wr_clk); #1;
    if (!wr_full) begin wr_en = 1; wr_data = val; end
    @(posedge wr_clk); #1; wr_en = 0;
  endtask

  // Read task
  task automatic read_word(output logic [DW-1:0] val);
    @(posedge rd_clk); #1;
    if (!rd_empty) rd_en = 1;
    @(posedge rd_clk); #1; rd_en = 0;
    val = rd_data;
  endtask

  initial begin
    $dumpfile("async_fifo_tb.vcd");
    $dumpvars(0, async_fifo_tb);
    wr_rst_n = 0; rd_rst_n = 0;
    wr_en = 0; rd_en = 0; wr_data = 0;
    repeat(4) @(posedge wr_clk);
    wr_rst_n = 1; rd_rst_n = 1;

    // Empty check
    @(posedge rd_clk); #1;
    if (!rd_empty) begin $error("FIFO not empty after reset"); fail_cnt++; end
    else pass_cnt++;

    // Write DEPTH words
    for (int i = 0; i < DEPTH; i++) write_word(i);

    // Full check
    @(posedge wr_clk); #1;
    repeat(4) @(posedge wr_clk); // allow gray sync
    if (!wr_full) begin $error("FIFO not full after %0d writes", DEPTH); fail_cnt++; end
    else pass_cnt++;

    // Read back and verify
    for (int i = 0; i < DEPTH; i++) begin
      logic [DW-1:0] got;
      read_word(got);
      // rd_data valid after rd_en pulse; data latched next cycle
      if (got !== DW'(i)) begin
        $error("Read[%0d] got %0d expected %0d", i, got, i);
        fail_cnt++;
      end else pass_cnt++;
    end

    // Empty again
    repeat(6) @(posedge rd_clk); #1;
    if (!rd_empty) begin $error("FIFO not empty after drain"); fail_cnt++; end
    else pass_cnt++;

    $display("async_fifo_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt == 0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
  initial begin #50000; $error("Timeout"); $finish; end
endmodule
