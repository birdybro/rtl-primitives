`timescale 1ns/1ps
module reset_controller_tb;
  parameter int ND = 2, SC = 4;
  logic clk, rst_n, por_req;
  logic [ND-1:0] rst_req, rst_n_out;
  int pass_cnt = 0, fail_cnt = 0;

  reset_controller #(.NUM_DOMAINS(ND), .STRETCH_CYCLES(SC)) dut (
    .clk(clk), .rst_n(rst_n), .por_req(por_req),
    .rst_req(rst_req), .rst_n_out(rst_n_out));

  initial clk = 0; always #5 clk = ~clk;
  task automatic tick; @(posedge clk); #1; endtask

  initial begin
    $dumpfile("reset_controller_tb.vcd");
    $dumpvars(0, reset_controller_tb);
    rst_n=0; por_req=0; rst_req=0;
    tick; tick; rst_n=1;

    // After reset: all domains released (rst_n_out=all-1)
    if (rst_n_out !== '1) begin $error("After reset rst_n_out=%0b expected all-1", rst_n_out); fail_cnt++; end
    else pass_cnt++;

    // POR request: both domains go into reset
    por_req=1; tick; por_req=0;
    if (rst_n_out !== '0) begin $error("After por_req rst_n_out=%0b expected all-0", rst_n_out); fail_cnt++; end
    else pass_cnt++;

    // Domain 0 deasserts after SC cycles (load value = SC*1 = 4)
    repeat(SC) tick;
    if (rst_n_out[0] !== 1'b1) begin $error("Domain 0 still in reset after %0d cycles", SC); fail_cnt++; end
    else pass_cnt++;
    // Domain 1 still in reset (load value = SC*2 = 8)
    if (rst_n_out[1] !== 1'b0) begin $error("Domain 1 deasserted too early"); fail_cnt++; end
    else pass_cnt++;

    // Domain 1 deasserts after another SC cycles
    repeat(SC) tick;
    if (rst_n_out[1] !== 1'b1) begin $error("Domain 1 still in reset after %0d cycles", SC*2); fail_cnt++; end
    else pass_cnt++;

    // Per-domain reset request
    rst_req[0]=1; tick; rst_req[0]=0;
    if (rst_n_out[0] !== 1'b0) begin $error("Domain 0 not in reset after rst_req[0]"); fail_cnt++; end
    else pass_cnt++;
    // Domain 1 unaffected
    if (rst_n_out[1] !== 1'b1) begin $error("Domain 1 affected by rst_req[0]"); fail_cnt++; end
    else pass_cnt++;

    $display("reset_controller_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt == 0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
  initial begin #10000; $error("Timeout"); $finish; end
endmodule
