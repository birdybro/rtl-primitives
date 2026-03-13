`timescale 1ns/1ps
module onehot_encoder_tb;
  parameter int W = 8;
  logic [W-1:0] in;
  logic [$clog2(W)-1:0] out;
  int pass_cnt = 0, fail_cnt = 0;

  // Tests bitops/onehot_encoder: in[W], out[$clog2(W)] (no valid port)
  onehot_encoder #(.WIDTH(W)) dut (.in(in), .out(out));

  task automatic check(input logic [W-1:0] oh, int exp_idx);
    in = oh; #1;
    if (out !== $clog2(W)'(exp_idx)) begin
      $error("in=%08b out=%0d expected %0d", oh, out, exp_idx); fail_cnt++;
    end else pass_cnt++;
  endtask

  initial begin
    $dumpfile("onehot_encoder_tb.vcd");
    $dumpvars(0, onehot_encoder_tb);

    // Each one-hot value -> correct binary index
    for (int i = 0; i < W; i++) begin
      check(W'(1 << i), i);
    end

    $display("onehot_encoder_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt == 0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
endmodule
