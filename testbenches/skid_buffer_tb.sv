`timescale 1ns/1ps
module skid_buffer_tb;
  parameter int DW=8;
  logic clk, rst_n;
  logic in_valid, in_ready;
  logic [DW-1:0] in_data;
  logic out_valid, out_ready;
  logic [DW-1:0] out_data;
  int pass_cnt=0, fail_cnt=0;
  int expected_queue[$];

  skid_buffer #(.DATA_WIDTH(DW)) dut (.*);

  initial clk=0; always #5 clk=~clk;
  task automatic tick; @(posedge clk); #1; endtask

  // Send a word if upstream ready
  task automatic send(input logic [DW-1:0] d);
    in_valid=1; in_data=d;
    while (!in_ready) tick;
    expected_queue.push_back(int'(d));
    tick;
    in_valid=0;
  endtask

  // Receive a word if downstream valid
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
    $dumpfile("skid_buffer_tb.vcd");
    $dumpvars(0, skid_buffer_tb);
    rst_n=0; in_valid=0; in_data=0; out_ready=0;
    tick; tick; rst_n=1;

    // Simple pass-through
    fork
      send(8'hA1);
      recv;
    join

    // Backpressure: send 2 words with out_ready=0 then drain
    in_valid=1; in_data=8'hB1; tick;
    in_data=8'hB2;
    expected_queue.push_back(8'hB1);
    tick; in_valid=0;
    expected_queue.push_back(8'hB2);
    out_ready=1;
    repeat(4) begin
      if (out_valid) begin
        int exp = expected_queue.pop_front();
        if (out_data !== DW'(exp)) begin $error("bp got %0h exp %0h", out_data, exp); fail_cnt++; end
        else pass_cnt++;
      end
      tick;
    end
    out_ready=0;

    // Burst: 4 words back-to-back with out_ready toggling
    for (int i=0; i<4; i++) begin
      in_valid=1; in_data=DW'(8'hC0+i); out_ready=(i%2==0);
      expected_queue.push_back(8'hC0+i);
      tick;
    end
    in_valid=0; out_ready=1;
    repeat(8) tick;
    out_ready=0;
    if (expected_queue.size()!=0) begin
      $error("Queue not drained, %0d items left", expected_queue.size()); fail_cnt++;
    end else pass_cnt++;

    $display("skid_buffer_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt==0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
  initial begin #10000; $error("Timeout"); $finish; end
endmodule
