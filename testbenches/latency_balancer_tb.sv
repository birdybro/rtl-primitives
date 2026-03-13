`timescale 1ns/1ps
module latency_balancer_tb;
  parameter int DW=8, LA=2, LB=4;
  logic clk, rst_n, en;
  logic [DW-1:0] din_a, din_b, dout_a, dout_b;
  int pass_cnt=0, fail_cnt=0;

  latency_balancer #(.DATA_WIDTH(DW), .LATENCY_A(LA), .LATENCY_B(LB)) dut (.*);

  initial clk=0; always #5 clk=~clk;
  task automatic tick; @(posedge clk); #1; endtask

  initial begin
    $dumpfile("latency_balancer_tb.vcd");
    $dumpvars(0, latency_balancer_tb);
    rst_n=0; en=0; din_a=0; din_b=0;
    tick; tick; rst_n=1;

    // Send same value on both paths; after LB cycles both outputs should match
    // Path A has LATENCY_A=2, gets extra (LB-LA)=2 delay stages added
    // Path B has LATENCY_B=4, passthrough (no extra delay)
    en=1;
    din_a=8'hAA; din_b=8'hAA;
    // After LB cycles, both outputs should have seen the input
    repeat(LB+2) tick;
    // Both dout_a and dout_b should be 0xAA (possibly delayed)
    // With en=1 continuously, after settling:
    if (dout_a !== 8'hAA) begin $error("dout_a=%0h expected AA", dout_a); fail_cnt++; end
    else pass_cnt++;
    if (dout_b !== 8'hAA) begin $error("dout_b=%0h expected AA", dout_b); fail_cnt++; end
    else pass_cnt++;

    // Change both inputs and verify they change together
    din_a=8'hBB; din_b=8'hBB;
    repeat(LB+2) tick;
    if (dout_a !== 8'hBB) begin $error("dout_a=%0h expected BB", dout_a); fail_cnt++; end
    else pass_cnt++;
    if (dout_b !== 8'hBB) begin $error("dout_b=%0h expected BB", dout_b); fail_cnt++; end
    else pass_cnt++;

    // en=0: outputs freeze
    en=0; din_a=8'hCC; din_b=8'hCC;
    tick; tick;
    if (dout_a !== 8'hBB) begin $error("dout_a changed while en=0: %0h", dout_a); fail_cnt++; end
    else pass_cnt++;
    if (dout_b !== 8'hBB) begin $error("dout_b changed while en=0: %0h", dout_b); fail_cnt++; end
    else pass_cnt++;

    $display("latency_balancer_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt==0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
  initial begin #5000; $error("Timeout"); $finish; end
endmodule
