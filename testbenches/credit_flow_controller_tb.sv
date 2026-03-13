`timescale 1ns/1ps
module credit_flow_controller_tb;
  parameter int DW=8, MC=4;
  logic clk, rst_n;
  logic credit_in, send_req, send_ack, recv_valid;
  logic [DW-1:0] send_data, recv_data;
  int pass_cnt=0, fail_cnt=0;

  credit_flow_controller #(.DATA_WIDTH(DW), .MAX_CREDITS(MC)) dut (
    .clk(clk), .rst_n(rst_n),
    .credit_in(credit_in),
    .send_req(send_req), .send_data(send_data), .send_ack(send_ack),
    .recv_valid(recv_valid), .recv_data(recv_data));

  initial clk=0; always #5 clk=~clk;
  task automatic tick; @(posedge clk); #1; endtask

  initial begin
    $dumpfile("credit_flow_controller_tb.vcd");
    $dumpvars(0, credit_flow_controller_tb);
    rst_n=0; credit_in=0; send_req=0; send_data=0;
    tick; tick; rst_n=1;

    // No credits: send should not be acknowledged
    send_req=1; send_data=8'hAA;
    tick; tick;
    if (send_ack) begin $error("send_ack without credits"); fail_cnt++; end
    else pass_cnt++;
    send_req=0;

    // Add credits, then send
    credit_in=1; tick; credit_in=0; // +1 credit
    credit_in=1; tick; credit_in=0; // +1 credit
    send_req=1; send_data=8'hBB;
    tick;
    if (!send_ack) begin $error("send_ack not asserted with credit"); fail_cnt++; end
    else pass_cnt++;
    if (!recv_valid) begin $error("recv_valid not set"); fail_cnt++; end
    else pass_cnt++;
    if (recv_data !== 8'hBB) begin $error("recv_data=%0h expected BB", recv_data); fail_cnt++; end
    else pass_cnt++;
    tick; send_req=0;

    // Second credit still available, send another
    send_req=1; send_data=8'hCC;
    tick;
    if (!send_ack) begin $error("2nd send_ack not asserted"); fail_cnt++; end
    else pass_cnt++;
    tick; send_req=0;

    // No more credits: no ack
    send_req=1; send_data=8'hDD; tick; tick;
    if (send_ack) begin $error("send_ack without remaining credits"); fail_cnt++; end
    else pass_cnt++;
    send_req=0;

    $display("credit_flow_controller_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt==0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
  initial begin #10000; $error("Timeout"); $finish; end
endmodule
