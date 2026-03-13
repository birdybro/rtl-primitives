`timescale 1ns/1ps
module up_down_counter_tb;
  parameter int W = 4;
  logic clk, rst_n, en, up_dn, load, overflow, underflow;
  logic [W-1:0] load_val, count;
  int pass_cnt = 0, fail_cnt = 0;

  up_down_counter #(.WIDTH(W)) dut (.clk(clk), .rst_n(rst_n), .en(en), .up_dn(up_dn),
    .load(load), .load_val(load_val), .count(count),
    .overflow(overflow), .underflow(underflow));

  initial clk = 0; always #5 clk = ~clk;
  task automatic tick; @(posedge clk); #1; endtask

  initial begin
    $dumpfile("up_down_counter_tb.vcd");
    $dumpvars(0, up_down_counter_tb);
    rst_n=0; en=0; up_dn=1; load=0; load_val=0;
    tick; tick; rst_n=1;

    // After reset count=0
    if (count !== 0) begin $error("After reset count=%0d", count); fail_cnt++; end
    else pass_cnt++;

    // Count up 5
    en=1; up_dn=1;
    repeat(5) tick;
    if (count !== 5) begin $error("count=%0d expected 5", count); fail_cnt++; end
    else pass_cnt++;

    // Count down 3
    up_dn=0;
    repeat(3) tick;
    if (count !== 2) begin $error("count=%0d expected 2", count); fail_cnt++; end
    else pass_cnt++;

    // Load value
    en=0; load=1; load_val=W'('1); tick; load=0;
    if (count !== W'('1)) begin $error("After load count=%0d expected MAX", count); fail_cnt++; end
    else pass_cnt++;

    // Overflow: count at max, count up
    en=1; up_dn=1; tick;
    if (!overflow) begin $error("overflow not set"); fail_cnt++; end
    else pass_cnt++;
    if (count !== 0) begin $error("After overflow count=%0d expected 0", count); fail_cnt++; end
    else pass_cnt++;

    // Underflow: count at 0, count down
    up_dn=0; tick;
    if (!underflow) begin $error("underflow not set"); fail_cnt++; end
    else pass_cnt++;
    if (count !== W'('1)) begin $error("After underflow count=%0d expected MAX", count); fail_cnt++; end
    else pass_cnt++;

    // en=0: no change
    en=0; tick;
    if (count !== W'('1)) begin $error("count changed while en=0: %0d", count); fail_cnt++; end
    else pass_cnt++;

    $display("up_down_counter_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt == 0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
  initial begin #5000; $error("Timeout"); $finish; end
endmodule
