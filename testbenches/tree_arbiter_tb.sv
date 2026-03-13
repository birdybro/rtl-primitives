`timescale 1ns/1ps
module tree_arbiter_tb;
  parameter int N = 8;
  logic [N-1:0] req, gnt;
  int pass_cnt = 0, fail_cnt = 0;

  tree_arbiter #(.NUM_REQS(N)) dut (.req(req), .gnt(gnt));

  task automatic check(input logic [N-1:0] r, logic [N-1:0] exp);
    req=r; #1;
    if (gnt !== exp) begin $error("req=%08b gnt=%08b exp=%08b", r, gnt, exp); fail_cnt++; end
    else pass_cnt++;
  endtask

  initial begin
    $dumpfile("tree_arbiter_tb.vcd");
    $dumpvars(0, tree_arbiter_tb);

    // No request
    check(8'b0000_0000, 8'b0000_0000);
    // Individual requestors
    for (int i=0; i<N; i++) begin
      check(8'(1<<i), 8'(1<<i));
    end
    // Multiple: lowest wins (tree gives priority to lowest bit)
    check(8'b1111_1111, 8'b0000_0001);
    check(8'b1111_1110, 8'b0000_0010);
    check(8'b1111_1100, 8'b0000_0100);
    check(8'b1111_1000, 8'b0000_1000);
    check(8'b1110_0000, 8'b0010_0000);

    $display("tree_arbiter_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt == 0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
endmodule
