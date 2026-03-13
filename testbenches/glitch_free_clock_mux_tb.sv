`timescale 1ns/1ps
module glitch_free_clock_mux_tb;
  logic clk0, clk1, sel, rst_n, clk_out;
  int pass_cnt = 0, fail_cnt = 0;
  int edge_cnt;

  glitch_free_clock_mux dut (.clk0(clk0), .clk1(clk1), .sel(sel), .rst_n(rst_n), .clk_out(clk_out));

  initial clk0 = 0; always #5  clk0 = ~clk0; // 100 MHz
  initial clk1 = 0; always #8  clk1 = ~clk1; //  62 MHz

  initial begin
    $dumpfile("glitch_free_clock_mux_tb.vcd");
    $dumpvars(0, glitch_free_clock_mux_tb);
    rst_n=0; sel=0;
    repeat(4) @(posedge clk0);
    rst_n=1;

    // sel=0: clk_out should follow clk0 (count ~10 rising edges in 100ns)
    sel=0;
    repeat(4) @(posedge clk0); // settle after reset release
    edge_cnt=0;
    fork
      begin repeat(10) @(posedge clk0); end
      begin forever begin @(posedge clk_out); edge_cnt++; end end
    join_any
    disable fork;
    if (edge_cnt < 8) begin $error("sel=0: only %0d clk_out edges in 10 clk0 periods", edge_cnt); fail_cnt++; end
    else pass_cnt++;

    // Switch to sel=1: after settling clk_out follows clk1
    @(negedge clk0); sel=1;
    repeat(8) @(posedge clk0); // allow handshake to complete
    edge_cnt=0;
    fork
      begin repeat(10) @(posedge clk1); end
      begin forever begin @(posedge clk_out); edge_cnt++; end end
    join_any
    disable fork;
    if (edge_cnt < 8) begin $error("sel=1: only %0d clk_out edges in 10 clk1 periods", edge_cnt); fail_cnt++; end
    else pass_cnt++;

    // Switch back to sel=0
    @(negedge clk1); sel=0;
    repeat(8) @(posedge clk1);
    edge_cnt=0;
    fork
      begin repeat(10) @(posedge clk0); end
      begin forever begin @(posedge clk_out); edge_cnt++; end end
    join_any
    disable fork;
    if (edge_cnt < 8) begin $error("sel=0 (2nd): only %0d clk_out edges", edge_cnt); fail_cnt++; end
    else pass_cnt++;

    $display("glitch_free_clock_mux_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt == 0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
  initial begin #50000; $error("Timeout"); $finish; end
endmodule
