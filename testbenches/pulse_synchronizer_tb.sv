`timescale 1ns/1ps
module pulse_synchronizer_tb;
  logic src_clk, src_rst_n, dst_clk, dst_rst_n;
  logic src_pulse, dst_pulse;
  int pass_cnt = 0, fail_cnt = 0;
  int pulse_cnt;

  pulse_synchronizer dut (.src_clk(src_clk), .src_rst_n(src_rst_n),
    .dst_clk(dst_clk), .dst_rst_n(dst_rst_n),
    .src_pulse(src_pulse), .dst_pulse(dst_pulse));

  initial src_clk = 0; always #5  src_clk = ~src_clk; // 100 MHz
  initial dst_clk = 0; always #8  dst_clk = ~dst_clk; //  62 MHz

  // Send a one-cycle pulse on src_clk domain
  task automatic send_src_pulse;
    @(posedge src_clk); #1; src_pulse = 1;
    @(posedge src_clk); #1; src_pulse = 0;
  endtask

  initial begin
    $dumpfile("pulse_synchronizer_tb.vcd");
    $dumpvars(0, pulse_synchronizer_tb);
    src_rst_n=0; dst_rst_n=0; src_pulse=0;
    repeat(4) @(posedge src_clk);
    src_rst_n=1; dst_rst_n=1;

    // Initial: no pulse
    @(posedge dst_clk); #1;
    if (dst_pulse) begin $error("dst_pulse asserted without src_pulse"); fail_cnt++; end
    else pass_cnt++;

    // Send one pulse and check it arrives in dst domain
    pulse_cnt = 0;
    send_src_pulse();
    repeat(10) @(posedge dst_clk); // allow time for propagation
    repeat(4) begin
      @(posedge dst_clk); #1;
      if (dst_pulse) pulse_cnt++;
    end
    if (pulse_cnt == 0) begin $error("dst_pulse never received"); fail_cnt++; end
    else pass_cnt++;

    // Send a second pulse
    pulse_cnt = 0;
    repeat(8) @(posedge dst_clk); // wait for synchronizer to settle
    send_src_pulse();
    repeat(10) @(posedge dst_clk);
    repeat(4) begin
      @(posedge dst_clk); #1;
      if (dst_pulse) pulse_cnt++;
    end
    if (pulse_cnt == 0) begin $error("2nd dst_pulse never received"); fail_cnt++; end
    else pass_cnt++;

    $display("pulse_synchronizer_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt == 0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
  initial begin #50000; $error("Timeout"); $finish; end
endmodule
