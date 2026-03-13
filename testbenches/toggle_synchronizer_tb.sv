`timescale 1ns/1ps
module toggle_synchronizer_tb;
  parameter int W = 1;
  logic src_clk, src_rst_n, dst_clk, dst_rst_n;
  logic [W-1:0] src_data, dst_data;
  int pass_cnt = 0, fail_cnt = 0;

  toggle_synchronizer #(.WIDTH(W)) dut (.src_clk(src_clk), .src_rst_n(src_rst_n),
    .dst_clk(dst_clk), .dst_rst_n(dst_rst_n),
    .src_data(src_data), .dst_data(dst_data));

  initial src_clk = 0; always #5  src_clk = ~src_clk; // 100 MHz
  initial dst_clk = 0; always #8  dst_clk = ~dst_clk; //  62 MHz

  initial begin
    $dumpfile("toggle_synchronizer_tb.vcd");
    $dumpvars(0, toggle_synchronizer_tb);
    src_rst_n=0; dst_rst_n=0; src_data=0;
    repeat(4) @(posedge src_clk);
    src_rst_n=1; dst_rst_n=1;

    // After reset dst_data=0
    repeat(4) @(posedge dst_clk); #1;
    if (dst_data !== 0) begin $error("After reset dst_data=%0b expected 0", dst_data); fail_cnt++; end
    else pass_cnt++;

    // Drive src_data=1, wait for propagation
    @(posedge src_clk); #1; src_data = 1;
    repeat(6) @(posedge dst_clk);
    #1;
    if (dst_data !== 1) begin $error("dst_data=%0b expected 1 after src=1", dst_data); fail_cnt++; end
    else pass_cnt++;

    // Drive src_data=0, wait for propagation
    @(posedge src_clk); #1; src_data = 0;
    repeat(6) @(posedge dst_clk);
    #1;
    if (dst_data !== 0) begin $error("dst_data=%0b expected 0 after src=0", dst_data); fail_cnt++; end
    else pass_cnt++;

    // Reset in dst domain clears output
    src_data = 1; repeat(4) @(posedge dst_clk);
    dst_rst_n = 0; @(posedge dst_clk); #1;
    if (dst_data !== 0) begin $error("dst_data=%0b expected 0 after dst reset", dst_data); fail_cnt++; end
    else pass_cnt++;
    dst_rst_n = 1;

    $display("toggle_synchronizer_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt == 0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
  initial begin #50000; $error("Timeout"); $finish; end
endmodule
