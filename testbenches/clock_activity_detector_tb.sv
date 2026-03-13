`timescale 1ns/1ps
module clock_activity_detector_tb;
  parameter int WC = 8;
  logic ref_clk, rst_n, mon_clk, active;
  int pass_cnt = 0, fail_cnt = 0;

  clock_activity_detector #(.WINDOW_CYCLES(WC)) dut (
    .ref_clk(ref_clk), .rst_n(rst_n), .mon_clk(mon_clk), .active(active));

  initial ref_clk = 0; always #10 ref_clk = ~ref_clk; // 50 MHz ref
  logic mon_en;
  initial mon_clk = 0;
  always @(posedge ref_clk) begin
    if (mon_en) mon_clk <= ~mon_clk;
  end

  task automatic ref_tick; @(posedge ref_clk); #1; endtask

  initial begin
    $dumpfile("clock_activity_detector_tb.vcd");
    $dumpvars(0, clock_activity_detector_tb);
    rst_n=0; mon_en=0;
    repeat(4) ref_tick; rst_n=1;

    // No mon_clk activity: active should remain low
    mon_en=0;
    repeat(WC*2) ref_tick;
    if (active) begin $error("active asserted without mon_clk"); fail_cnt++; end
    else pass_cnt++;

    // Enable mon_clk and wait for detector to see activity
    mon_en=1;
    repeat(WC*3) ref_tick;
    if (!active) begin $error("active not asserted with mon_clk running"); fail_cnt++; end
    else pass_cnt++;

    // Stop mon_clk: active should deassert after a window
    mon_en=0; mon_clk=0;
    repeat(WC*2+2) ref_tick;
    if (active) begin $error("active still set after mon_clk stopped"); fail_cnt++; end
    else pass_cnt++;

    $display("clock_activity_detector_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt == 0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
  initial begin #50000; $error("Timeout"); $finish; end
endmodule
