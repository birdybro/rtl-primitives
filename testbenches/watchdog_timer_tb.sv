`timescale 1ns/1ps
module watchdog_timer_tb;
  parameter int TW = 8;
  logic clk, rst_n, kick, timeout;
  logic [TW-1:0] timeout_val;
  int pass_cnt = 0, fail_cnt = 0;

  watchdog_timer #(.TIMEOUT_WIDTH(TW)) dut (
    .clk(clk), .rst_n(rst_n), .kick(kick),
    .timeout_val(timeout_val), .timeout(timeout));

  initial clk = 0; always #5 clk = ~clk;
  task automatic tick; @(posedge clk); #1; endtask

  initial begin
    $dumpfile("watchdog_timer_tb.vcd");
    $dumpvars(0, watchdog_timer_tb);
    rst_n=0; kick=0; timeout_val=0;
    tick; tick; rst_n=1;

    // No kick: timeout after timeout_val cycles
    timeout_val = 4; kick=0;
    repeat(5) tick;
    if (!timeout) begin $error("timeout not set after %0d cycles", 4); fail_cnt++; end
    else pass_cnt++;

    // Kick prevents timeout
    rst_n=0; tick; rst_n=1;
    timeout_val=8;
    repeat(3) begin
      tick;
      kick=1; tick; kick=0;
    end
    repeat(4) tick;
    if (timeout) begin $error("timeout set despite regular kicks"); fail_cnt++; end
    else pass_cnt++;

    // After stop kicking, timeout fires
    kick=0;
    repeat(9) tick;
    if (!timeout) begin $error("timeout not set after stop kicking"); fail_cnt++; end
    else pass_cnt++;

    // Reset clears timeout
    rst_n=0; tick; rst_n=1; tick;
    if (timeout) begin $error("timeout still set after reset"); fail_cnt++; end
    else pass_cnt++;

    $display("watchdog_timer_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt == 0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
  initial begin #10000; $error("Timeout"); $finish; end
endmodule
