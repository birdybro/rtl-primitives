`timescale 1ns/1ps
module gray_decoder_tb;
  parameter int W=8;
  logic [W-1:0] gray_in, bin_out;
  int pass_cnt=0, fail_cnt=0;

  gray_decoder #(.WIDTH(W)) dut (.gray_in(gray_in), .bin_out(bin_out));

  initial begin
    $dumpfile("gray_decoder_tb.vcd");
    $dumpvars(0, gray_decoder_tb);

    // Test round-trip: encode then decode should give original binary
    for (int i=0; i<(1<<W); i++) begin
      automatic logic [W-1:0] gray = W'(i) ^ (W'(i) >> 1);
      gray_in = gray; #1;
      if (bin_out !== W'(i)) begin
        $error("gray=%0b bin_out=%0d expected %0d", gray, bin_out, i); fail_cnt++;
      end else pass_cnt++;
    end

    // Spot-check known values
    // gray(0) = 0b00000000 -> binary 0
    gray_in=8'b0000_0000; #1;
    if (bin_out !== 8'd0) begin $error("gray=00 bin=%0d expected 0", bin_out); fail_cnt++; end
    else pass_cnt++;
    // gray(1) = 0b00000001 -> binary 1
    gray_in=8'b0000_0001; #1;
    if (bin_out !== 8'd1) begin $error("gray=01 bin=%0d expected 1", bin_out); fail_cnt++; end
    else pass_cnt++;
    // gray(2) = 0b00000011 -> binary 2
    gray_in=8'b0000_0011; #1;
    if (bin_out !== 8'd2) begin $error("gray=11 bin=%0d expected 2", bin_out); fail_cnt++; end
    else pass_cnt++;
    // gray(7) = 0b00000100 -> binary 7
    gray_in=8'b0000_0100; #1;
    if (bin_out !== 8'd7) begin $error("gray=100 bin=%0d expected 7", bin_out); fail_cnt++; end
    else pass_cnt++;

    $display("gray_decoder_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt==0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
endmodule
