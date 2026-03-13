`timescale 1ns/1ps
module dual_port_ram_tb;
  parameter int DW=8, DEPTH=16, AW=$clog2(DEPTH);
  logic clk_a, en_a, we_a;
  logic [AW-1:0] addr_a;
  logic [DW-1:0] din_a, dout_a;
  logic clk_b, en_b, we_b;
  logic [AW-1:0] addr_b;
  logic [DW-1:0] din_b, dout_b;
  int pass_cnt=0, fail_cnt=0;

  dual_port_ram #(.DATA_WIDTH(DW), .DEPTH(DEPTH)) dut (.*);

  initial clk_a=0; always #5  clk_a=~clk_a;
  initial clk_b=0; always #7  clk_b=~clk_b;

  initial begin
    $dumpfile("dual_port_ram_tb.vcd");
    $dumpvars(0, dual_port_ram_tb);
    {en_a,we_a,en_b,we_b}=0; addr_a=0; addr_b=0; din_a=0; din_b=0;

    // Port A writes
    for (int i=0; i<DEPTH; i++) begin
      @(posedge clk_a); #1;
      en_a=1; we_a=1; addr_a=AW'(i); din_a=DW'(i*3+1);
    end
    @(posedge clk_a); #1; en_a=0; we_a=0;

    // Port A reads back
    for (int i=0; i<DEPTH; i++) begin
      @(posedge clk_a); #1;
      en_a=1; we_a=0; addr_a=AW'(i);
      @(posedge clk_a); #1; // 1-cycle read latency
      if (dout_a !== DW'(i*3+1)) begin
        $error("PortA read[%0d]=%0d expected %0d", i, dout_a, i*3+1); fail_cnt++;
      end else pass_cnt++;
    end
    en_a=0;

    // Port B writes different pattern
    for (int i=0; i<DEPTH; i++) begin
      @(posedge clk_b); #1;
      en_b=1; we_b=1; addr_b=AW'(i); din_b=DW'(i*5+2);
    end
    @(posedge clk_b); #1; en_b=0; we_b=0;

    // Port A reads Port B's writes
    for (int i=0; i<DEPTH; i++) begin
      @(posedge clk_a); #1;
      en_a=1; we_a=0; addr_a=AW'(i);
      @(posedge clk_a); #1;
      if (dout_a !== DW'(i*5+2)) begin
        $error("CrossPort read[%0d]=%0d expected %0d", i, dout_a, i*5+2); fail_cnt++;
      end else pass_cnt++;
    end
    en_a=0;

    $display("dual_port_ram_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt==0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
  initial begin #50000; $error("Timeout"); $finish; end
endmodule
