`timescale 1ns/1ps
module simple_fifo_tb;
  parameter int DW=8, DEPTH=8;
  logic clk, rst_n, wr_en, rd_en;
  logic [DW-1:0] wr_data, rd_data;
  logic full, empty;
  logic [$clog2(DEPTH+1)-1:0] count;
  int pass_cnt=0, fail_cnt=0;

  simple_fifo #(.DATA_WIDTH(DW), .DEPTH(DEPTH)) dut (.*);

  initial clk=0; always #5 clk=~clk;
  task automatic tick; @(posedge clk); #1; endtask

  initial begin
    $dumpfile("simple_fifo_tb.vcd");
    $dumpvars(0, simple_fifo_tb);
    rst_n=0; wr_en=0; rd_en=0; wr_data=0;
    tick; tick; rst_n=1;

    // Should be empty
    if (!empty || full) begin $error("After reset: empty=%0b full=%0b", empty, full); fail_cnt++; end
    else pass_cnt++;

    // Push DEPTH words
    for (int i=0; i<DEPTH; i++) begin
      wr_en=1; wr_data=DW'(i+1); tick; wr_en=0;
    end
    if (!full) begin $error("Not full after %0d pushes", DEPTH); fail_cnt++; end
    else pass_cnt++;

    // Pop all and verify
    for (int i=0; i<DEPTH; i++) begin
      rd_en=1; tick; rd_en=0;
      if (rd_data !== DW'(i+1)) begin
        $error("Pop[%0d]=%0d expected %0d", i, rd_data, i+1); fail_cnt++;
      end else pass_cnt++;
    end
    if (!empty) begin $error("Not empty after drain"); fail_cnt++; end
    else pass_cnt++;

    // Simultaneous push and pop
    wr_en=1; wr_data=8'hAB; rd_en=0; tick; wr_en=0; // push AB
    wr_en=1; wr_data=8'hCD; rd_en=1; tick; wr_en=0; rd_en=0; // push CD, pop AB
    if (rd_data !== 8'hAB) begin $error("Simul pop got %0h expected AB", rd_data); fail_cnt++; end
    else pass_cnt++;

    $display("simple_fifo_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt==0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
  initial begin #10000; $error("Timeout"); $finish; end
endmodule
