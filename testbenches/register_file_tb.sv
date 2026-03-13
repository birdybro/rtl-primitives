`timescale 1ns/1ps
module register_file_tb;
  parameter int DW=8, NR=8, NRP=2;
  logic clk, rst_n, we;
  logic [$clog2(NR)-1:0] waddr;
  logic [DW-1:0] wdata;
  logic [NRP-1:0][$clog2(NR)-1:0] raddr;
  logic [NRP-1:0][DW-1:0] rdata;
  int pass_cnt=0, fail_cnt=0;

  register_file #(.DATA_WIDTH(DW), .NUM_REGS(NR), .NUM_READ_PORTS(NRP)) dut (.*);

  initial clk=0; always #5 clk=~clk;
  task automatic tick; @(posedge clk); #1; endtask

  initial begin
    $dumpfile("register_file_tb.vcd");
    $dumpvars(0, register_file_tb);
    rst_n=0; we=0; waddr=0; wdata=0; raddr=0;
    tick; tick; rst_n=1;

    // After reset: all regs=0
    for (int i=0; i<NR; i++) begin
      raddr[0] = $clog2(NR)'(i); #1;
      if (rdata[0] !== 0) begin $error("reg[%0d]=%0h expected 0 after reset", i, rdata[0]); fail_cnt++; end
      else pass_cnt++;
    end

    // Write reg 3 = 0xAB
    we=1; waddr=3; wdata=8'hAB; tick; we=0;
    raddr[0]=3; #1;
    if (rdata[0] !== 8'hAB) begin $error("reg[3]=%0h expected AB", rdata[0]); fail_cnt++; end
    else pass_cnt++;

    // Write reg 5 = 0xCD
    we=1; waddr=5; wdata=8'hCD; tick; we=0;
    raddr[0]=5; #1;
    if (rdata[0] !== 8'hCD) begin $error("reg[5]=%0h expected CD", rdata[0]); fail_cnt++; end
    else pass_cnt++;

    // Read two ports simultaneously
    raddr[0]=3; raddr[1]=5; #1;
    if (rdata[0] !== 8'hAB) begin $error("port0 reg[3]=%0h expected AB", rdata[0]); fail_cnt++; end
    else pass_cnt++;
    if (rdata[1] !== 8'hCD) begin $error("port1 reg[5]=%0h expected CD", rdata[1]); fail_cnt++; end
    else pass_cnt++;

    // Write-to-read forwarding: read same reg being written
    we=1; waddr=3; wdata=8'hEF;
    raddr[0]=3; #1;
    if (rdata[0] !== 8'hEF) begin $error("forwarding: rdata[0]=%0h expected EF", rdata[0]); fail_cnt++; end
    else pass_cnt++;
    tick; we=0;

    // Other regs unaffected
    raddr[0]=5; #1;
    if (rdata[0] !== 8'hCD) begin $error("reg[5] changed unexpectedly: %0h", rdata[0]); fail_cnt++; end
    else pass_cnt++;

    $display("register_file_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt==0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
  initial begin #5000; $error("Timeout"); $finish; end
endmodule
