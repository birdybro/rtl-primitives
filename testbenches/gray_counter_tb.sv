`timescale 1ns/1ps
module gray_counter_tb;
  parameter int W = 4;
  logic clk, rst_n, en;
  logic [W-1:0] count_gray, count_bin;
  int pass_cnt = 0, fail_cnt = 0;

  gray_counter #(.WIDTH(W)) dut (.clk(clk), .rst_n(rst_n), .en(en),
    .count_gray(count_gray), .count_bin(count_bin));

  initial clk = 0; always #5 clk = ~clk;

  initial begin
    $dumpfile("gray_counter_tb.vcd");
    $dumpvars(0, gray_counter_tb);
    rst_n=0; en=0;
    @(posedge clk); @(posedge clk); #1; rst_n=1;

    // After reset both should be 0
    @(posedge clk); #1;
    if (count_gray !== 0 || count_bin !== 0) begin
      $error("After reset gray=%04b bin=%04b", count_gray, count_bin); fail_cnt++;
    end else pass_cnt++;

    // Run through 2^W steps and verify one-bit transition in Gray code
    en = 1;
    for (int i = 0; i < (1<<W); i++) begin
      logic [W-1:0] prev_gray;
      prev_gray = count_gray;
      @(posedge clk); #1;
      begin
        int diff = $countones(count_gray ^ prev_gray);
        if (diff !== 1) begin
          $error("Step %0d: gray changed by %0d bits (%04b->%04b)", i, diff, prev_gray, count_gray);
          fail_cnt++;
        end else pass_cnt++;
      end
    end

    $display("gray_counter_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt == 0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
  initial begin #10000; $error("Timeout"); $finish; end
endmodule
