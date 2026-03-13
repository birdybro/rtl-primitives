`timescale 1ns/1ps
module reset_stretcher_tb;
  parameter int SC = 4;
  logic clk, rst_n, stretched_rst_n;
  int pass_cnt = 0, fail_cnt = 0;

  reset_stretcher #(.STRETCH_CYCLES(SC)) dut (
    .clk(clk), .rst_n(rst_n), .stretched_rst_n(stretched_rst_n));

  initial clk = 0; always #5 clk = ~clk;
  task automatic tick; @(posedge clk); #1; endtask

  initial begin
    $dumpfile("reset_stretcher_tb.vcd");
    $dumpvars(0, reset_stretcher_tb);
    rst_n = 0;
    tick; tick;

    // While rst_n=0, stretched_rst_n=0
    if (stretched_rst_n !== 1'b0) begin $error("stretched_rst_n=%0b expected 0 while rst_n=0", stretched_rst_n); fail_cnt++; end
    else pass_cnt++;

    // Release rst_n; stretched should remain 0 for SC cycles
    rst_n = 1;
    repeat(SC-1) begin
      tick;
      if (stretched_rst_n !== 1'b0) begin
        $error("stretched_rst_n=%0b expected 0 during stretch", stretched_rst_n); fail_cnt++;
      end else pass_cnt++;
    end

    // After SC cycles, stretched_rst_n should deassert
    tick;
    if (stretched_rst_n !== 1'b1) begin $error("stretched_rst_n=%0b expected 1 after stretch", stretched_rst_n); fail_cnt++; end
    else pass_cnt++;

    // Re-assert rst_n: stretched goes low immediately, restarts counter
    rst_n = 0; #1;
    if (stretched_rst_n !== 1'b0) begin $error("stretched_rst_n=%0b expected 0 on re-assert", stretched_rst_n); fail_cnt++; end
    else pass_cnt++;
    tick;
    rst_n = 1;
    repeat(SC) tick;
    if (stretched_rst_n !== 1'b1) begin $error("stretched_rst_n=%0b expected 1 after 2nd stretch", stretched_rst_n); fail_cnt++; end
    else pass_cnt++;

    $display("reset_stretcher_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt == 0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
  initial begin #10000; $error("Timeout"); $finish; end
endmodule
