`timescale 1ns/1ps
module up_counter_tb;
  parameter int W = 4;
  logic clk, rst_n, en, load;
  logic [W-1:0] load_val, count;
  logic overflow;
  int pass_cnt = 0, fail_cnt = 0;

  up_counter #(.WIDTH(W)) dut (.clk(clk), .rst_n(rst_n), .en(en),
    .load(load), .load_val(load_val), .count(count), .overflow(overflow));

  initial clk = 0; always #5 clk = ~clk;

  task automatic tick; @(posedge clk); #1; endtask

  initial begin
    $dumpfile("up_counter_tb.vcd");
    $dumpvars(0, up_counter_tb);
    rst_n=0; en=0; load=0; load_val=0;
    tick; tick; rst_n=1;

    // After reset count=0
    if (count !== 0) begin $error("After reset count=%0d", count); fail_cnt++; end
    else pass_cnt++;

    // Count up 5 times
    en=1;
    repeat(5) tick;
    if (count !== 5) begin $error("count=%0d expected 5", count); fail_cnt++; end
    else pass_cnt++;

    // Load value
    en=0; load=1; load_val=10; tick;
    load=0;
    if (count !== 10) begin $error("After load count=%0d expected 10", count); fail_cnt++; end
    else pass_cnt++;

    // Count to overflow: load MAX-1 and enable
    en=0; load=1; load_val='1; tick; load=0;
    en=1; tick; // should overflow
    if (!overflow) begin $error("overflow not set"); fail_cnt++; end
    else pass_cnt++;
    // count should wrap to 0
    if (count !== 0) begin $error("After overflow count=%0d expected 0", count); fail_cnt++; end
    else pass_cnt++;

    // Disable stops counting
    en=0; tick;
    if (count !== 1) begin $error("Unexpected count after overflow+1 = %0d", count); fail_cnt++; end
    else pass_cnt++; // en=0 but count already incremented above to 1

    en=0; tick;
    if (count !== 1) begin $error("count changed while en=0: %0d", count); fail_cnt++; end
    else pass_cnt++;

    $display("up_counter_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt == 0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
  initial begin #5000; $error("Timeout"); $finish; end
endmodule
