`timescale 1ns/1ps
module line_buffer_tb;
  parameter int DW=8, LW=4, NL=3;
  logic clk, rst_n, wr_en, line_valid;
  logic [DW-1:0] wr_data;
  logic [$clog2(LW)-1:0] pixel_col;
  logic [NL-1:0][DW-1:0] line_out;
  int pass_cnt=0, fail_cnt=0;

  line_buffer #(.DATA_WIDTH(DW), .LINE_WIDTH(LW), .NUM_LINES(NL)) dut (.*);

  initial clk=0; always #5 clk=~clk;
  task automatic tick; @(posedge clk); #1; endtask

  // Write one full line of pixels
  task automatic write_line(input logic [DW-1:0] base_val);
    for (int c=0; c<LW; c++) begin
      wr_en=1; wr_data=DW'(base_val+c); tick;
    end
    wr_en=0;
  endtask

  initial begin
    $dumpfile("line_buffer_tb.vcd");
    $dumpvars(0, line_buffer_tb);
    rst_n=0; wr_en=0; wr_data=0;
    tick; tick; rst_n=1;

    // Initially: not valid
    if (line_valid) begin $error("line_valid set after reset"); fail_cnt++; end
    else pass_cnt++;

    // Write NL-1=2 full lines: valid should still be 0 until NL lines loaded
    write_line(8'h10); // line 0
    write_line(8'h20); // line 1
    if (line_valid) begin $error("line_valid set after %0d lines", NL-1); fail_cnt++; end
    else pass_cnt++;

    // Write NL-th line: valid should become 1
    write_line(8'h30); // line 2
    if (!line_valid) begin $error("line_valid not set after %0d lines", NL); fail_cnt++; end
    else pass_cnt++;

    // Write another line: still valid
    write_line(8'h40);
    if (!line_valid) begin $error("line_valid cleared after another line"); fail_cnt++; end
    else pass_cnt++;

    // After reset: valid clears
    rst_n=0; tick; rst_n=1;
    if (line_valid) begin $error("line_valid set after 2nd reset"); fail_cnt++; end
    else pass_cnt++;

    $display("line_buffer_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt==0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
  initial begin #10000; $error("Timeout"); $finish; end
endmodule
