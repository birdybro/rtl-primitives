`timescale 1ns/1ps
module round_robin_arbiter_tb;
  parameter int N = 4;
  logic clk, rst_n;
  logic [N-1:0] req, gnt;
  int pass_cnt = 0, fail_cnt = 0;

  round_robin_arbiter #(.NUM_REQS(N)) dut (.clk(clk), .rst_n(rst_n), .req(req), .gnt(gnt));

  initial clk = 0; always #5 clk = ~clk;

  initial begin
    $dumpfile("round_robin_arbiter_tb.vcd");
    $dumpvars(0, round_robin_arbiter_tb);
    rst_n = 0; req = 0;
    @(posedge clk); @(posedge clk);
    rst_n = 1;

    // All requestors active - verify each gets a grant in rotation
    req = 4'b1111;
    begin
      logic [N-1:0] seen = 0;
      repeat(N*2) begin
        @(posedge clk); #1;
        if ($countones(gnt) > 1) begin $error("Multiple grants: %04b", gnt); fail_cnt++; end
        seen |= gnt;
      end
      if (seen === 4'b1111) pass_cnt++;
      else begin $error("Not all requestors granted; seen=%04b", seen); fail_cnt++; end
    end

    // Single requestor
    req = 4'b0100;
    repeat(4) @(posedge clk); #1;
    if (gnt !== 4'b0100) begin $error("Single req gnt=%04b expected 0100", gnt); fail_cnt++; end
    else pass_cnt++;

    // No request
    req = 4'b0000;
    @(posedge clk); #1;
    if (gnt !== 4'b0000) begin $error("No req but gnt=%04b", gnt); fail_cnt++; end
    else pass_cnt++;

    $display("round_robin_arbiter_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt == 0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
  initial begin #10000; $error("Timeout"); $finish; end
endmodule
