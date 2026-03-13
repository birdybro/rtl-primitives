`timescale 1ns/1ps
module reset_bridge_tb;
  logic src_clk, dst_clk, src_rst_n, dst_rst_n;
  int pass_cnt = 0, fail_cnt = 0;

  reset_bridge #(.STAGES(2)) dut (
    .src_clk(src_clk), .src_rst_n(src_rst_n),
    .dst_clk(dst_clk), .dst_rst_n(dst_rst_n));

  initial src_clk = 0; always #5  src_clk = ~src_clk;
  initial dst_clk = 0; always #8  dst_clk = ~dst_clk;

  initial begin
    $dumpfile("reset_bridge_tb.vcd");
    $dumpvars(0, reset_bridge_tb);
    src_rst_n = 0;

    // While src_rst_n=0, dst_rst_n should be 0 (async assert)
    #2;
    if (dst_rst_n !== 1'b0) begin $error("dst_rst_n=%0b expected 0 while src_rst_n=0", dst_rst_n); fail_cnt++; end
    else pass_cnt++;

    // Release: dst_rst_n should deassert after 2 dst_clk cycles
    @(posedge dst_clk); #1; src_rst_n = 1;
    if (dst_rst_n !== 1'b0) begin $error("dst_rst_n=%0b expected 0 after 0 cycles", dst_rst_n); fail_cnt++; end
    else pass_cnt++;
    @(posedge dst_clk); #1;
    if (dst_rst_n !== 1'b0) begin $error("dst_rst_n=%0b expected 0 after 1 cycle", dst_rst_n); fail_cnt++; end
    else pass_cnt++;
    @(posedge dst_clk); #1;
    if (dst_rst_n !== 1'b1) begin $error("dst_rst_n=%0b expected 1 after 2 cycles", dst_rst_n); fail_cnt++; end
    else pass_cnt++;

    // Assert src_rst_n again - dst_rst_n goes low immediately
    src_rst_n = 0; #1;
    if (dst_rst_n !== 1'b0) begin $error("dst_rst_n=%0b expected 0 on re-assert", dst_rst_n); fail_cnt++; end
    else pass_cnt++;

    // Release and re-check
    @(posedge dst_clk); #1; src_rst_n = 1;
    @(posedge dst_clk); @(posedge dst_clk); #1;
    if (dst_rst_n !== 1'b1) begin $error("dst_rst_n=%0b expected 1 on 2nd release", dst_rst_n); fail_cnt++; end
    else pass_cnt++;

    $display("reset_bridge_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt == 0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
  initial begin #10000; $error("Timeout"); $finish; end
endmodule
