`timescale 1ns/1ps
module sync_2ff_tb;
  logic clk_src, clk_dst, rst_n, d, q;
  int pass_cnt = 0, fail_cnt = 0;

  sync_2ff #(.RESET_VAL(1'b0)) dut (.clk(clk_dst), .rst_n(rst_n), .d(d), .q(q));

  initial clk_src = 0;
  always #5  clk_src = ~clk_src; // 100 MHz
  initial clk_dst = 0;
  always #7  clk_dst = ~clk_dst; // ~71 MHz

  initial begin
    $dumpfile("sync_2ff_tb.vcd");
    $dumpvars(0, sync_2ff_tb);
    rst_n = 0; d = 0;
    @(posedge clk_dst); @(posedge clk_dst);
    rst_n = 1;

    // After reset q should be 0
    @(posedge clk_dst); #1;
    if (q !== 1'b0) begin $error("After reset q=%0b expected 0", q); fail_cnt++; end
    else pass_cnt++;

    // Assert d in src domain, wait for q to stabilize in dst domain
    @(posedge clk_src); #1; d = 1;
    repeat(4) @(posedge clk_dst);
    #1;
    if (q !== 1'b1) begin $error("q=%0b expected 1 after d=1 propagation", q); fail_cnt++; end
    else pass_cnt++;

    // De-assert d
    @(posedge clk_src); #1; d = 0;
    repeat(4) @(posedge clk_dst);
    #1;
    if (q !== 1'b0) begin $error("q=%0b expected 0 after d=0 propagation", q); fail_cnt++; end
    else pass_cnt++;

    // Reset while d=1
    d = 1; @(posedge clk_dst); #1;
    rst_n = 0; @(posedge clk_dst); #1;
    if (q !== 1'b0) begin $error("q=%0b expected 0 after reset", q); fail_cnt++; end
    else pass_cnt++;

    $display("sync_2ff_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt == 0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end

  // Timeout
  initial begin
    #10000;
    $error("Timeout"); $finish;
  end
endmodule
