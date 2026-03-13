`timescale 1ns/1ps
module power_on_reset_tb;
  parameter int D = 8;
  logic clk, por_rst_n;
  int pass_cnt = 0, fail_cnt = 0;

  power_on_reset #(.DEPTH(D)) dut (.clk(clk), .por_rst_n(por_rst_n));

  initial clk = 0; always #5 clk = ~clk;
  task automatic tick; @(posedge clk); #1; endtask

  initial begin
    $dumpfile("power_on_reset_tb.vcd");
    $dumpvars(0, power_on_reset_tb);

    // At power-up, por_rst_n should be LOW (active reset)
    #1;
    if (por_rst_n !== 1'b0) begin $error("por_rst_n=%0b expected 0 at power-up", por_rst_n); fail_cnt++; end
    else pass_cnt++;

    // Should remain low for at least D clock cycles
    repeat(D-1) begin
      tick;
      if (por_rst_n !== 1'b0) begin
        $error("por_rst_n=%0b deasserted early", por_rst_n); fail_cnt++;
      end else pass_cnt++;
    end

    // After D cycles, por_rst_n should deassert
    tick; tick; // one extra
    if (por_rst_n !== 1'b1) begin $error("por_rst_n=%0b expected 1 after %0d cycles", por_rst_n, D); fail_cnt++; end
    else pass_cnt++;

    // Should remain high indefinitely
    repeat(4) tick;
    if (por_rst_n !== 1'b1) begin $error("por_rst_n went low again"); fail_cnt++; end
    else pass_cnt++;

    $display("power_on_reset_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt == 0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
  initial begin #5000; $error("Timeout"); $finish; end
endmodule
