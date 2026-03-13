`timescale 1ns/1ps
module ready_valid_stage_tb;
  parameter int DW = 8;
  logic clk, rst_n;
  logic in_valid, in_ready;
  logic [DW-1:0] in_data;
  logic out_valid, out_ready;
  logic [DW-1:0] out_data;
  int pass_cnt = 0, fail_cnt = 0;
  int expected_queue[$];

  ready_valid_stage #(.DATA_WIDTH(DW)) dut (.*);

  initial clk=0; always #5 clk=~clk;
  task automatic tick; @(posedge clk); #1; endtask

  task automatic send(input logic [DW-1:0] d);
    in_valid=1; in_data=d;
    while (!in_ready) tick;
    expected_queue.push_back(int'(d));
    tick; in_valid=0;
  endtask

  task automatic recv;
    out_ready=1;
    while (!out_valid) tick;
    begin
      int exp = expected_queue.pop_front();
      if (out_data !== DW'(exp)) begin
        $error("recv got %0h expected %0h", out_data, exp); fail_cnt++;
      end else pass_cnt++;
    end
    tick; out_ready=0;
  endtask

  initial begin
    $dumpfile("ready_valid_stage_tb.vcd");
    $dumpvars(0, ready_valid_stage_tb);
    rst_n=0; in_valid=0; in_data=0; out_ready=0;
    tick; tick; rst_n=1;

    // Simple pass-through
    fork send(8'hA1); recv; join

    // Send 3 back-to-back with out_ready held
    out_ready=1;
    for (int i=0; i<3; i++) begin
      in_valid=1; in_data=DW'(8'hB0+i);
      expected_queue.push_back(8'hB0+i);
      tick;
    end
    in_valid=0;
    repeat(5) tick;
    out_ready=0;
    if (expected_queue.size()!=0) begin $error("%0d items not drained", expected_queue.size()); fail_cnt++; end
    else pass_cnt++;

    // Backpressure: send then drain
    fork send(8'hCC); recv; join

    $display("ready_valid_stage_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt==0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
  initial begin #10000; $error("Timeout"); $finish; end
endmodule
