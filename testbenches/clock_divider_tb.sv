`timescale 1ns/1ps
module clock_divider_tb;
  parameter int DIV_BY=4;
  logic clk, rst_n, en, div_clk_en;
  int pass_cnt=0, fail_cnt=0;
  int cycle_count=0, en_count=0;

  clock_divider #(.DIV_BY(DIV_BY)) dut (.clk(clk), .rst_n(rst_n), .en(en), .div_clk_en(div_clk_en));

  initial clk=0; always #5 clk=~clk;

  // Count how many cycles between div_clk_en pulses
  always @(posedge clk) begin
    if (rst_n) begin
      cycle_count <= cycle_count + 1;
      if (div_clk_en) en_count <= en_count + 1;
    end
  end

  initial begin
    $dumpfile("clock_divider_tb.vcd");
    $dumpvars(0, clock_divider_tb);
    rst_n=0; en=0;
    repeat(4) @(posedge clk); #1;
    rst_n=1;

    // With en=0, no pulses expected
    repeat(DIV_BY*2) @(posedge clk); #1;
    if (en_count!==0) begin $error("en=0 but en_count=%0d", en_count); fail_cnt++; end
    else pass_cnt++;

    // Enable and count pulses over DIV_BY*10 cycles
    en=1; en_count=0; cycle_count=0;
    repeat(DIV_BY*10) @(posedge clk); #1;
    if (en_count!==10) begin $error("Expected 10 pulses, got %0d", en_count); fail_cnt++; end
    else pass_cnt++;

    // Verify spacing: capture timestamps of pulses
    begin
      int last_pulse=-1, spacing=-1;
      int pulse_ok=1;
      en_count=0;
      for (int c=0; c<DIV_BY*8; c++) begin
        @(posedge clk); #1;
        if (div_clk_en) begin
          if (last_pulse>=0) begin
            spacing = c - last_pulse;
            if (spacing!==DIV_BY) begin
              $error("Pulse spacing=%0d expected %0d", spacing, DIV_BY); fail_cnt++;
              pulse_ok=0;
            end
          end
          last_pulse=c;
          en_count++;
        end
      end
      if (pulse_ok && en_count>0) pass_cnt++;
    end

    // Disable mid-stream stops pulses
    en=0; en_count=0;
    repeat(DIV_BY*3) @(posedge clk); #1;
    if (en_count!==0) begin $error("After en=0 got %0d pulses", en_count); fail_cnt++; end
    else pass_cnt++;

    $display("clock_divider_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt==0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
  initial begin #50000; $error("Timeout"); $finish; end
endmodule
