`timescale 1ns/1ps
module gray_encoder_tb;
  parameter int W=8;
  logic [W-1:0] bin_in, gray_out;
  int pass_cnt=0, fail_cnt=0;

  gray_encoder #(.WIDTH(W)) dut (.bin_in(bin_in), .gray_out(gray_out));

  initial begin
    $dumpfile("gray_encoder_tb.vcd");
    $dumpvars(0, gray_encoder_tb);

    // Test all values 0..2^W-1
    for (int i=0; i<(1<<W); i++) begin
      bin_in=W'(i); #1;
      // Verify standard Gray encode: g = b ^ (b >> 1)
      begin
        logic [W-1:0] exp_gray = W'(i) ^ (W'(i) >> 1);
        if (gray_out !== exp_gray) begin
          $error("bin=%0d gray=%0b expected %0b", i, gray_out, exp_gray); fail_cnt++;
        end else pass_cnt++;
      end
    end

    // Verify one-bit transitions between consecutive values
    for (int i=0; i<(1<<W)-1; i++) begin
      logic [W-1:0] g0, g1;
      bin_in=W'(i);   #1; g0=gray_out;
      bin_in=W'(i+1); #1; g1=gray_out;
      if ($countones(g0^g1)!==1) begin
        $error("Transition %0d->%0d: %0d bits changed", i, i+1, $countones(g0^g1)); fail_cnt++;
      end else pass_cnt++;
    end

    $display("gray_encoder_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt==0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
endmodule
