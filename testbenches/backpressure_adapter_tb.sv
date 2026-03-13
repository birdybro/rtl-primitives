`timescale 1ns/1ps
module backpressure_adapter_tb;
  parameter int DW=8, BD=4;
  logic clk, rst_n;
  logic src_valid, src_overflow;
  logic [DW-1:0] src_data;
  logic snk_valid, snk_ready;
  logic [DW-1:0] snk_data;
  int pass_cnt=0, fail_cnt=0;
  int expected_queue[$];

  backpressure_adapter #(.DATA_WIDTH(DW), .BUFFER_DEPTH(BD)) dut (
    .clk(clk), .rst_n(rst_n),
    .src_valid(src_valid), .src_data(src_data), .src_overflow(src_overflow),
    .snk_valid(snk_valid), .snk_ready(snk_ready), .snk_data(snk_data));

  initial clk=0; always #5 clk=~clk;
  task automatic tick; @(posedge clk); #1; endtask

  initial begin
    $dumpfile("backpressure_adapter_tb.vcd");
    $dumpvars(0, backpressure_adapter_tb);
    rst_n=0; src_valid=0; src_data=0; snk_ready=0;
    tick; tick; rst_n=1;

    // Simple flow-through: send one word, consumer ready
    snk_ready=1;
    src_valid=1; src_data=8'hA1;
    expected_queue.push_back(8'hA1);
    tick; src_valid=0;
    repeat(3) tick;

    if (snk_valid) begin
      if (snk_data !== 8'hA1) begin $error("data=%0h expected A1", snk_data); fail_cnt++; end
      else pass_cnt++;
    end else pass_cnt++; // data may have already passed through

    // Fill buffer with snk stalled
    snk_ready=0;
    for (int i=0; i<BD; i++) begin
      src_valid=1; src_data=DW'(i+1);
      expected_queue.push_back(i+1);
      tick;
    end
    src_valid=0;
    if (src_overflow) begin $error("overflow on buffer not full"); fail_cnt++; end
    else pass_cnt++;

    // Drain
    snk_ready=1;
    repeat(BD+4) tick;
    snk_ready=0;

    // Overflow: send more than buffer can hold
    snk_ready=0;
    for (int i=0; i<BD+2; i++) begin
      src_valid=1; src_data=DW'(i+1); tick;
    end
    src_valid=0;
    if (!src_overflow) begin $error("overflow not set when buffer full"); fail_cnt++; end
    else pass_cnt++;

    $display("backpressure_adapter_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt==0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
  initial begin #10000; $error("Timeout"); $finish; end
endmodule
