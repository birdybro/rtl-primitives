`timescale 1ns/1ps
module down_counter_tb;
  parameter int W = 8;
  logic clk, rst_n, en, load;
  logic [W-1:0] load_val, count;
  logic underflow;
  int pass_cnt = 0, fail_cnt = 0;

  down_counter #(.WIDTH(W)) dut (.clk(clk), .rst_n(rst_n), .en(en),
    .load(load), .load_val(load_val), .count(count), .underflow(underflow));

  initial clk = 0; always #5 clk = ~clk;
  task automatic tick; @(posedge clk); #1; endtask

  initial begin
    $dumpfile("down_counter_tb.vcd");
    $dumpvars(0, down_counter_tb);
    rst_n=0; en=0; load=0; load_val=0;
    tick; tick; rst_n=1;

    // After reset count should be 0 (or max, depending on impl) - verify underflow not asserted
    if (underflow) begin $error("underflow set at reset"); fail_cnt++; end
    else pass_cnt++;

    // Load 5 and count down
    load=1; load_val=5; tick; load=0;
    if (count !== 5) begin $error("After load count=%0d expected 5", count); fail_cnt++; end
    else pass_cnt++;

    en=1;
    repeat(5) tick;
    if (count !== 0) begin $error("count=%0d expected 0 after 5 downs", count); fail_cnt++; end
    else pass_cnt++;

    // Underflow: count at 0, decrement
    tick;
    if (!underflow) begin $error("underflow not set"); fail_cnt++; end
    else pass_cnt++;
    // count wraps to MAX
    if (count !== W'('1)) begin $error("After underflow count=%0d expected MAX", count); fail_cnt++; end
    else pass_cnt++;

    // Disable stops counting
    en=0; load=1; load_val=10; tick; load=0;
    en=0; tick;
    if (count !== 10) begin $error("count changed while en=0: %0d", count); fail_cnt++; end
    else pass_cnt++;

    $display("down_counter_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt == 0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
  initial begin #5000; $error("Timeout"); $finish; end
endmodule
