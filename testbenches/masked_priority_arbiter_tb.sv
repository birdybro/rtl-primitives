`timescale 1ns/1ps
module masked_priority_arbiter_tb;
  parameter int N = 4;
  logic [N-1:0] req, mask, gnt;
  int pass_cnt = 0, fail_cnt = 0;

  masked_priority_arbiter #(.NUM_REQS(N)) dut (.req(req), .mask(mask), .gnt(gnt));

  task automatic check(
    input logic [N-1:0] r, m, logic [N-1:0] exp
  );
    req=r; mask=m; #1;
    if (gnt !== exp) begin $error("req=%04b mask=%04b gnt=%04b exp=%04b", r, m, gnt, exp); fail_cnt++; end
    else pass_cnt++;
  endtask

  initial begin
    $dumpfile("masked_priority_arbiter_tb.vcd");
    $dumpvars(0, masked_priority_arbiter_tb);

    // No mask bits: no grant
    check(4'b1111, 4'b0000, 4'b0000);
    // Single unmasked requestor
    check(4'b1111, 4'b0001, 4'b0001);
    check(4'b1111, 4'b0010, 4'b0010);
    check(4'b1111, 4'b0100, 4'b0100);
    check(4'b1111, 4'b1000, 4'b1000);
    // Multiple unmasked: lowest wins
    check(4'b1111, 4'b1111, 4'b0001);
    check(4'b1110, 4'b1110, 4'b0010);
    check(4'b1100, 4'b1111, 4'b0100);
    // Mask disables higher priority requestors
    check(4'b1111, 4'b1100, 4'b0100); // bits 0,1 masked out of grant
    // No request matching mask
    check(4'b0001, 4'b1110, 4'b0000);
    // All zeros req
    check(4'b0000, 4'b1111, 4'b0000);

    $display("masked_priority_arbiter_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt == 0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
endmodule
