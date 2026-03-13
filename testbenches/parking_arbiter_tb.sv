`timescale 1ns/1ps
module parking_arbiter_tb;
  parameter int N = 4;
  logic clk, rst_n;
  logic [N-1:0] req, gnt;
  int pass_cnt = 0, fail_cnt = 0;

  parking_arbiter #(.NUM_REQS(N)) dut (.clk(clk), .rst_n(rst_n), .req(req), .gnt(gnt));

  initial clk = 0; always #5 clk = ~clk;
  task automatic tick; @(posedge clk); #1; endtask

  initial begin
    $dumpfile("parking_arbiter_tb.vcd");
    $dumpvars(0, parking_arbiter_tb);
    rst_n=0; req=0;
    tick; tick; rst_n=1;

    // No request: grant parks (keeps last winner or 0)
    req=0; tick;
    if ($countones(gnt) > 1) begin $error("Multiple grants with no req: %04b", gnt); fail_cnt++; end
    else pass_cnt++;

    // Single requestor
    req=4'b0010; tick;
    if (gnt !== 4'b0010) begin $error("Single req gnt=%04b expected 0010", gnt); fail_cnt++; end
    else pass_cnt++;

    // Park: drop request, grant stays on last winner
    begin
      logic [N-1:0] last = gnt;
      req=0; tick;
      if (gnt !== last) begin $error("Parked gnt=%04b expected %04b", gnt, last); fail_cnt++; end
      else pass_cnt++;
    end

    // Multiple requestors: only one gets grant
    req=4'b1111;
    repeat(N) begin
      tick;
      if ($countones(gnt) > 1) begin $error("Multiple grants: %04b", gnt); fail_cnt++; end
      else pass_cnt++;
    end

    // All zeroed out
    req=0; tick;
    if ($countones(gnt) > 1) begin $error("Multiple grants with req=0: %04b", gnt); fail_cnt++; end
    else pass_cnt++;

    $display("parking_arbiter_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt == 0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
  initial begin #10000; $error("Timeout"); $finish; end
endmodule
