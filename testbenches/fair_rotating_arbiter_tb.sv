`timescale 1ns/1ps
module fair_rotating_arbiter_tb;
  parameter int N = 4;
  logic clk, rst_n;
  logic [N-1:0] req, gnt;
  int pass_cnt = 0, fail_cnt = 0;

  fair_rotating_arbiter #(.NUM_REQS(N)) dut (.clk(clk), .rst_n(rst_n), .req(req), .gnt(gnt));

  initial clk = 0; always #5 clk = ~clk;
  task automatic tick; @(posedge clk); #1; endtask

  initial begin
    $dumpfile("fair_rotating_arbiter_tb.vcd");
    $dumpvars(0, fair_rotating_arbiter_tb);
    rst_n=0; req=0;
    tick; tick; rst_n=1;

    // No request -> no grant
    req=0; tick;
    if (gnt !== 0) begin $error("gnt=%04b expected 0 with no req", gnt); fail_cnt++; end
    else pass_cnt++;

    // All requestors: verify each gets a turn (fairness)
    req = 4'b1111;
    begin
      logic [N-1:0] seen = 0;
      repeat(N*2) begin
        tick;
        if ($countones(gnt) > 1) begin $error("Multiple grants: %04b", gnt); fail_cnt++; end
        seen |= gnt;
      end
      if (seen === 4'b1111) pass_cnt++;
      else begin $error("Not all requestors granted; seen=%04b", seen); fail_cnt++; end
    end

    // Single requestor always gets grant
    req = 4'b0010;
    repeat(4) tick;
    if (gnt !== 4'b0010) begin $error("Single req gnt=%04b expected 0010", gnt); fail_cnt++; end
    else pass_cnt++;

    // No request: no grant
    req = 0; tick;
    if (gnt !== 0) begin $error("gnt=%04b expected 0 with req=0", gnt); fail_cnt++; end
    else pass_cnt++;

    $display("fair_rotating_arbiter_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt == 0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
  initial begin #10000; $error("Timeout"); $finish; end
endmodule
