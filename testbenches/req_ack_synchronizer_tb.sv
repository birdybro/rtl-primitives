`timescale 1ns/1ps
module req_ack_synchronizer_tb;
  logic src_clk, src_rst_n, dst_clk, dst_rst_n;
  logic src_req, src_ack, dst_pulse;
  int pass_cnt = 0, fail_cnt = 0;
  int pulse_cnt;

  req_ack_synchronizer dut (.src_clk(src_clk), .src_rst_n(src_rst_n),
    .dst_clk(dst_clk), .dst_rst_n(dst_rst_n),
    .src_req(src_req), .src_ack(src_ack), .dst_pulse(dst_pulse));

  initial src_clk = 0; always #5  src_clk = ~src_clk; // 100 MHz
  initial dst_clk = 0; always #8  dst_clk = ~dst_clk; //  62 MHz

  initial begin
    $dumpfile("req_ack_synchronizer_tb.vcd");
    $dumpvars(0, req_ack_synchronizer_tb);
    src_rst_n=0; dst_rst_n=0; src_req=0;
    repeat(4) @(posedge src_clk);
    src_rst_n=1; dst_rst_n=1;

    // No req: no dst_pulse
    repeat(4) @(posedge dst_clk); #1;
    if (dst_pulse) begin $error("spurious dst_pulse"); fail_cnt++; end
    else pass_cnt++;

    // Assert req and wait for ack
    @(posedge src_clk); #1; src_req = 1;
    begin
      int wait_cyc = 0;
      while (!src_ack && wait_cyc < 20) begin
        @(posedge src_clk); #1;
        wait_cyc++;
      end
      if (!src_ack) begin $error("src_ack never received"); fail_cnt++; end
      else pass_cnt++;
    end

    // dst_pulse should have fired
    pulse_cnt=0;
    @(posedge dst_clk); #1;
    if (dst_pulse) pulse_cnt++;
    @(posedge dst_clk); #1;
    if (dst_pulse) pulse_cnt++;
    if (pulse_cnt == 0) begin $error("dst_pulse never observed"); fail_cnt++; end
    else pass_cnt++;

    // Deassert req, wait for ack to clear
    @(posedge src_clk); #1; src_req = 0;
    begin
      int wait_cyc = 0;
      while (src_ack && wait_cyc < 20) begin
        @(posedge src_clk); #1;
        wait_cyc++;
      end
      if (src_ack) begin $error("src_ack still set after req=0"); fail_cnt++; end
      else pass_cnt++;
    end

    $display("req_ack_synchronizer_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt == 0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
  initial begin #50000; $error("Timeout"); $finish; end
endmodule
