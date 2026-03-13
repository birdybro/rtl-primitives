`timescale 1ns/1ps
module bundled_data_synchronizer_tb;
  parameter int DW = 8;
  logic src_clk, src_rst_n, dst_clk, dst_rst_n;
  logic src_valid, src_ready, dst_valid, dst_ready;
  logic [DW-1:0] src_data, dst_data;
  int pass_cnt = 0, fail_cnt = 0;

  bundled_data_synchronizer #(.DATA_WIDTH(DW)) dut (
    .src_clk(src_clk), .src_rst_n(src_rst_n),
    .dst_clk(dst_clk), .dst_rst_n(dst_rst_n),
    .src_valid(src_valid), .src_data(src_data), .src_ready(src_ready),
    .dst_valid(dst_valid), .dst_data(dst_data), .dst_ready(dst_ready));

  initial src_clk = 0; always #5  src_clk = ~src_clk; // 100 MHz
  initial dst_clk = 0; always #8  dst_clk = ~dst_clk; //  62 MHz

  initial begin
    $dumpfile("bundled_data_synchronizer_tb.vcd");
    $dumpvars(0, bundled_data_synchronizer_tb);
    src_rst_n=0; dst_rst_n=0; src_valid=0; src_data=0; dst_ready=0;
    repeat(4) @(posedge src_clk);
    src_rst_n=1; dst_rst_n=1;

    // No transfer: dst_valid=0
    repeat(3) @(posedge dst_clk); #1;
    if (dst_valid) begin $error("spurious dst_valid"); fail_cnt++; end
    else pass_cnt++;

    // Send data=8'hAB and wait until src_ready
    @(posedge src_clk); #1;
    src_valid = 1; src_data = 8'hAB;
    begin
      int wait_cyc = 0;
      while (!src_ready && wait_cyc < 30) begin
        @(posedge src_clk); #1;
        wait_cyc++;
      end
      if (!src_ready) begin $error("src_ready never asserted"); fail_cnt++; end
      else pass_cnt++;
    end
    @(posedge src_clk); #1; src_valid = 0;

    // Wait for dst_valid and check data
    begin
      int wait_cyc = 0;
      while (!dst_valid && wait_cyc < 20) begin
        @(posedge dst_clk); #1;
        wait_cyc++;
      end
      if (!dst_valid) begin $error("dst_valid never asserted"); fail_cnt++; end
      else pass_cnt++;
      if (dst_data !== 8'hAB) begin $error("dst_data=%0h expected AB", dst_data); fail_cnt++; end
      else pass_cnt++;
    end

    // Acknowledge in dst domain
    dst_ready = 1; @(posedge dst_clk); #1; dst_ready = 0;

    $display("bundled_data_synchronizer_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt == 0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
  initial begin #50000; $error("Timeout"); $finish; end
endmodule
