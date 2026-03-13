`timescale 1ns/1ps
module weighted_round_robin_arbiter_tb;
  parameter int N = 4, WW = 4;
  logic clk, rst_n;
  logic [N-1:0] req, gnt;
  logic [N-1:0][WW-1:0] weight;
  int pass_cnt = 0, fail_cnt = 0;
  int grant_count [N];

  weighted_round_robin_arbiter #(.NUM_REQS(N), .WEIGHT_WIDTH(WW)) dut (
    .clk(clk), .rst_n(rst_n), .req(req), .weight(weight), .gnt(gnt));

  initial clk = 0; always #5 clk = ~clk;
  task automatic tick; @(posedge clk); #1; endtask

  initial begin
    $dumpfile("weighted_round_robin_arbiter_tb.vcd");
    $dumpvars(0, weighted_round_robin_arbiter_tb);
    rst_n=0; req=0;
    for (int i=0; i<N; i++) weight[i]=0;
    tick; tick; rst_n=1;

    // No request: no grant
    req=0; tick;
    if (gnt !== 0) begin $error("gnt=%04b expected 0 with no req", gnt); fail_cnt++; end
    else pass_cnt++;

    // Single requestor with weight=1
    req=4'b0001; weight[0]=1; tick;
    if (gnt !== 4'b0001) begin $error("Single req gnt=%04b expected 0001", gnt); fail_cnt++; end
    else pass_cnt++;

    // All requestors: verify only one granted per cycle
    req=4'b1111;
    for (int i=0; i<N; i++) weight[i]=WW'(i+1);
    for (int i=0; i<N; i++) grant_count[i]=0;
    repeat(N*4) begin
      tick;
      if ($countones(gnt) > 1) begin $error("Multiple grants: %04b", gnt); fail_cnt++; end
      for (int i=0; i<N; i++) begin
        if (gnt[i]) grant_count[i]++;
      end
    end
    // All requestors should have gotten at least one grant
    begin
      logic all_granted = 1;
      for (int i=0; i<N; i++) begin
        if (grant_count[i] == 0) all_granted = 0;
      end
      if (!all_granted) begin $error("Some requestors never granted"); fail_cnt++; end
      else pass_cnt++;
    end

    // Higher weight gets more grants (verify req[3] > req[0] over time)
    for (int i=0; i<N; i++) grant_count[i]=0;
    repeat(40) begin
      tick;
      for (int i=0; i<N; i++) if (gnt[i]) grant_count[i]++;
    end
    if (grant_count[3] <= grant_count[0]) begin
      $error("Weight not respected: cnt[3]=%0d cnt[0]=%0d", grant_count[3], grant_count[0]); fail_cnt++;
    end else pass_cnt++;

    $display("weighted_round_robin_arbiter_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt == 0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
  initial begin #10000; $error("Timeout"); $finish; end
endmodule
