`timescale 1ns/1ps
// Tests encoding/onehot_encoder (ports: onehot_in, bin_out, valid)
// (Distinct from bitops/onehot_encoder which has ports: in, out, no valid)
module enc_onehot_encoder_tb;
  parameter int W = 8;
  logic [W-1:0] onehot_in;
  logic [$clog2(W)-1:0] bin_out;
  logic valid;
  int pass_cnt = 0, fail_cnt = 0;

  onehot_encoder #(.WIDTH(W)) dut (.onehot_in(onehot_in), .bin_out(bin_out), .valid(valid));

  task automatic check(input logic [W-1:0] oh, int exp_idx, logic exp_valid);
    onehot_in = oh; #1;
    if (valid !== exp_valid) begin $error("in=%08b valid=%0b expected %0b", oh, valid, exp_valid); fail_cnt++; end
    else pass_cnt++;
    if (exp_valid && bin_out !== $clog2(W)'(exp_idx)) begin
      $error("in=%08b bin_out=%0d expected %0d", oh, bin_out, exp_idx); fail_cnt++;
    end else if (exp_valid) pass_cnt++;
  endtask

  initial begin
    $dumpfile("enc_onehot_encoder_tb.vcd");
    $dumpvars(0, enc_onehot_encoder_tb);

    // All zeros: valid=0
    check(8'b0000_0000, 0, 1'b0);

    // Each one-hot bit
    for (int i = 0; i < W; i++) begin
      check(W'(1 << i), i, 1'b1);
    end

    $display("enc_onehot_encoder_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt == 0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
endmodule
