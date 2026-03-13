`timescale 1ns/1ps
module clock_gating_wrapper_tb;
  logic clk, en, te, gated_clk;
  int pass_cnt = 0, fail_cnt = 0;
  int gated_cycles, expected;

  clock_gating_wrapper dut (.clk(clk), .en(en), .te(te), .gated_clk(gated_clk));

  initial clk = 0; always #5 clk = ~clk;

  // Count rising edges of gated_clk over N input clk cycles
  task automatic count_gated_edges(input int num_cycles, output int cnt);
    cnt = 0;
    repeat(num_cycles) begin
      @(posedge clk);
    end
    // Count by observing gated_clk transitions
  endtask

  initial begin
    $dumpfile("clock_gating_wrapper_tb.vcd");
    $dumpvars(0, clock_gating_wrapper_tb);
    en=0; te=0;

    // When en=0, te=0: gated_clk should never go high
    @(negedge clk); // set during low phase
    en=0; te=0;
    gated_cycles=0;
    fork
      begin
        repeat(10) @(posedge clk);
      end
      begin
        forever begin
          @(posedge gated_clk);
          gated_cycles++;
        end
      end
    join_any
    disable fork;
    if (gated_cycles !== 0) begin $error("gated_clk toggled when en=0: %0d pulses", gated_cycles); fail_cnt++; end
    else pass_cnt++;

    // When en=1: gated_clk should follow clk
    @(negedge clk); en=1; te=0;
    gated_cycles=0;
    fork
      begin
        repeat(8) @(posedge clk);
      end
      begin
        forever begin
          @(posedge gated_clk);
          gated_cycles++;
        end
      end
    join_any
    disable fork;
    if (gated_cycles < 6) begin $error("gated_clk only %0d pulses expected ~8 when en=1", gated_cycles); fail_cnt++; end
    else pass_cnt++;

    // When te=1 (scan bypass): gated_clk should pass regardless of en
    @(negedge clk); en=0; te=1;
    gated_cycles=0;
    fork
      begin
        repeat(8) @(posedge clk);
      end
      begin
        forever begin
          @(posedge gated_clk);
          gated_cycles++;
        end
      end
    join_any
    disable fork;
    if (gated_cycles < 6) begin $error("gated_clk only %0d pulses expected ~8 when te=1", gated_cycles); fail_cnt++; end
    else pass_cnt++;

    $display("clock_gating_wrapper_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt == 0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
  initial begin #5000; $error("Timeout"); $finish; end
endmodule
