`timescale 1ns/1ps
module mailbox_fifo_tb;
  parameter int DW=8;
  logic clk, rst_n;
  logic wr_valid, wr_ready;
  logic [DW-1:0] wr_data;
  logic rd_valid, rd_ready;
  logic [DW-1:0] rd_data;
  int pass_cnt=0, fail_cnt=0;

  mailbox_fifo #(.DATA_WIDTH(DW)) dut (.*);

  initial clk=0; always #5 clk=~clk;
  task automatic tick; @(posedge clk); #1; endtask

  initial begin
    $dumpfile("mailbox_fifo_tb.vcd");
    $dumpvars(0, mailbox_fifo_tb);
    rst_n=0; wr_valid=0; wr_data=0; rd_ready=0;
    tick; tick; rst_n=1;

    // Initially empty: rd_valid=0
    if (rd_valid) begin $error("rd_valid set after reset"); fail_cnt++; end
    else pass_cnt++;

    // Write data: wait for wr_ready
    wr_valid=1; wr_data=8'hAA;
    while (!wr_ready) tick;
    tick; wr_valid=0;

    // rd_valid should assert
    begin
      int wait_cyc=0;
      while (!rd_valid && wait_cyc<10) begin tick; wait_cyc++; end
    end
    if (!rd_valid) begin $error("rd_valid never asserted"); fail_cnt++; end
    else pass_cnt++;
    if (rd_data !== 8'hAA) begin $error("rd_data=%0h expected AA", rd_data); fail_cnt++; end
    else pass_cnt++;

    // Read the data
    rd_ready=1; tick; rd_ready=0;
    tick;
    if (rd_valid) begin $error("rd_valid still set after read"); fail_cnt++; end
    else pass_cnt++;

    // Write then read several values
    for (int i=0; i<4; i++) begin
      wr_valid=1; wr_data=DW'(i+1);
      while (!wr_ready) tick;
      tick; wr_valid=0; tick;
      if (!rd_valid) begin $error("rd_valid not set for item %0d", i); fail_cnt++; end
      else begin
        if (rd_data !== DW'(i+1)) begin $error("rd_data[%0d]=%0h expected %0h", i, rd_data, i+1); fail_cnt++; end
        else pass_cnt++;
        rd_ready=1; tick; rd_ready=0;
      end
    end
    pass_cnt++; // loop passed

    $display("mailbox_fifo_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt==0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
  initial begin #10000; $error("Timeout"); $finish; end
endmodule
