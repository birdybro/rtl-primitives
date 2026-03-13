`timescale 1ns/1ps
module pipeline_register_slice_tb;
  parameter int DW = 8;
  logic clk, rst_n;
  logic up_valid, up_ready;
  logic [DW-1:0] up_data;
  logic dn_valid, dn_ready;
  logic [DW-1:0] dn_data;
  int pass_cnt = 0, fail_cnt = 0;
  int expected_queue[$];

  pipeline_register_slice #(.DATA_WIDTH(DW)) dut (.*);

  initial clk=0; always #5 clk=~clk;
  task automatic tick; @(posedge clk); #1; endtask

  task automatic send(input logic [DW-1:0] d);
    up_valid=1; up_data=d;
    while (!up_ready) tick;
    expected_queue.push_back(int'(d));
    tick; up_valid=0;
  endtask

  task automatic recv;
    dn_ready=1;
    while (!dn_valid) tick;
    begin
      int exp = expected_queue.pop_front();
      if (dn_data !== DW'(exp)) begin
        $error("recv got %0h expected %0h", dn_data, exp); fail_cnt++;
      end else pass_cnt++;
    end
    tick; dn_ready=0;
  endtask

  initial begin
    $dumpfile("pipeline_register_slice_tb.vcd");
    $dumpvars(0, pipeline_register_slice_tb);
    rst_n=0; up_valid=0; up_data=0; dn_ready=0;
    tick; tick; rst_n=1;

    // Simple transfer
    fork send(8'hA5); recv; join

    // Multiple back-to-back
    for (int i=0; i<4; i++) begin
      fork
        send(DW'(8'hC0+i));
        recv;
      join
    end

    // Send without immediate downstream ready
    up_valid=1; up_data=8'hFF;
    expected_queue.push_back(8'hFF);
    while (!up_ready) tick;
    tick; up_valid=0;
    repeat(3) tick; // backpressure delay
    dn_ready=1;
    while (!dn_valid) tick;
    begin
      int exp = expected_queue.pop_front();
      if (dn_data !== DW'(exp)) begin $error("bp recv %0h expected %0h", dn_data, exp); fail_cnt++; end
      else pass_cnt++;
    end
    tick; dn_ready=0;

    $display("pipeline_register_slice_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt==0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
  initial begin #10000; $error("Timeout"); $finish; end
endmodule
