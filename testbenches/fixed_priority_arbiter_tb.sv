`timescale 1ns/1ps
module fixed_priority_arbiter_tb;
  parameter int N = 4;
  logic [N-1:0] req, gnt;
  int pass_cnt = 0, fail_cnt = 0;

  fixed_priority_arbiter #(.NUM_REQS(N)) dut (.req(req), .gnt(gnt));

  task automatic check(input logic [N-1:0] r, logic [N-1:0] exp);
    req = r; #1;
    if (gnt !== exp) begin $error("req=%04b gnt=%04b expected=%04b", r, gnt, exp); fail_cnt++; end
    else pass_cnt++;
  endtask

  initial begin
    $dumpfile("fixed_priority_arbiter_tb.vcd");
    $dumpvars(0, fixed_priority_arbiter_tb);

    // No request -> no grant
    check(4'b0000, 4'b0000);
    // Single requests
    check(4'b0001, 4'b0001);
    check(4'b0010, 4'b0010);
    check(4'b0100, 4'b0100);
    check(4'b1000, 4'b1000);
    // Multiple: lowest bit wins
    check(4'b1111, 4'b0001);
    check(4'b1110, 4'b0010);
    check(4'b1100, 4'b0100);
    check(4'b1010, 4'b0010);
    check(4'b0110, 4'b0010);
    check(4'b1001, 4'b0001);

    $display("fixed_priority_arbiter_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt == 0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
endmodule
