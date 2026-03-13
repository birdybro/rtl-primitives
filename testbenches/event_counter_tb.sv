`timescale 1ns/1ps
module event_counter_tb;
  parameter int W = 8;
  logic clk, rst_n, event_in, threshold_hit, clr;
  logic [W-1:0] threshold, count;
  int pass_cnt = 0, fail_cnt = 0;

  event_counter #(.WIDTH(W)) dut (.clk(clk), .rst_n(rst_n), .event_in(event_in),
    .threshold(threshold), .count(count), .threshold_hit(threshold_hit), .clr(clr));

  initial clk = 0; always #5 clk = ~clk;
  task automatic tick; @(posedge clk); #1; endtask

  initial begin
    $dumpfile("event_counter_tb.vcd");
    $dumpvars(0, event_counter_tb);
    rst_n=0; event_in=0; threshold=0; clr=0;
    tick; tick; rst_n=1;

    // After reset count=0
    if (count !== 0) begin $error("After reset count=%0d", count); fail_cnt++; end
    else pass_cnt++;

    // Count 4 events with threshold=4
    threshold = 4;
    event_in=1; tick; event_in=0;
    event_in=1; tick; event_in=0;
    event_in=1; tick; event_in=0;
    event_in=1; tick; event_in=0;
    if (count !== 4) begin $error("count=%0d expected 4", count); fail_cnt++; end
    else pass_cnt++;
    if (!threshold_hit) begin $error("threshold_hit not set at count=4"); fail_cnt++; end
    else pass_cnt++;

    // Clear resets count
    clr=1; tick; clr=0;
    if (count !== 0) begin $error("After clr count=%0d expected 0", count); fail_cnt++; end
    else pass_cnt++;
    if (threshold_hit) begin $error("threshold_hit still set after clear"); fail_cnt++; end
    else pass_cnt++;

    // Event while clr is asserted: count stays 0
    clr=1; event_in=1; tick; clr=0; event_in=0;
    if (count !== 0) begin $error("Event+clr count=%0d expected 0", count); fail_cnt++; end
    else pass_cnt++;

    $display("event_counter_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt == 0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
  initial begin #5000; $error("Timeout"); $finish; end
endmodule
