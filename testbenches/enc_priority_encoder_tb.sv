`timescale 1ns/1ps
// Tests encoding/priority_encoder (ports: req, enc, valid)
// (Distinct from bitops/priority_encoder which has ports: in, out, valid)
module enc_priority_encoder_tb;
  parameter int W = 8;
  logic [W-1:0] req;
  logic [$clog2(W)-1:0] enc;
  logic valid;
  int pass_cnt = 0, fail_cnt = 0;

  priority_encoder #(.WIDTH(W)) dut (.req(req), .enc(enc), .valid(valid));

  initial begin
    $dumpfile("enc_priority_encoder_tb.vcd");
    $dumpvars(0, enc_priority_encoder_tb);

    // All zeros: valid=0
    req = 8'b0; #1;
    if (valid !== 1'b0) begin $error("All-0: valid=%0b expected 0", valid); fail_cnt++; end
    else pass_cnt++;

    // Each individual bit: enc should be that bit's index
    for (int i = 0; i < W; i++) begin
      req = W'(1 << i); #1;
      if (!valid) begin $error("bit %0d: valid=0", i); fail_cnt++; end
      else if (enc !== $clog2(W)'(i)) begin $error("bit %0d: enc=%0d expected %0d", i, enc, i); fail_cnt++; end
      else pass_cnt++;
    end

    // All ones: lowest bit (0) wins
    req = '1; #1;
    if (enc !== 0 || !valid) begin $error("All-1: enc=%0d valid=%0b", enc, valid); fail_cnt++; end
    else pass_cnt++;

    // Multiple bits: bit 3 and bit 6, expect 3
    req = 8'b0100_1000; #1;
    if (enc !== 3 || !valid) begin $error("Multi: enc=%0d expected 3", enc); fail_cnt++; end
    else pass_cnt++;

    $display("enc_priority_encoder_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt == 0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
endmodule
