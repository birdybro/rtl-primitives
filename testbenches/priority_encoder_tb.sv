`timescale 1ns/1ps
module priority_encoder_tb;
  parameter int W = 8;
  logic [W-1:0]         in;
  logic [$clog2(W)-1:0] out;
  logic                 valid;
  int pass_cnt = 0, fail_cnt = 0;

  priority_encoder #(.WIDTH(W)) dut (.in(in), .out(out), .valid(valid));

  initial begin
    $dumpfile("priority_encoder_tb.vcd");
    $dumpvars(0, priority_encoder_tb);

    // All zeros: valid=0
    in = 8'b0; #1;
    if (valid !== 1'b0) begin $error("All-0: valid=%0b expected 0", valid); fail_cnt++; end
    else pass_cnt++;

    // Each individual bit
    for (int i = 0; i < W; i++) begin
      in = 1 << i; #1;
      if (!valid) begin $error("bit %0d: valid=0", i); fail_cnt++; end
      else if (out !== $clog2(W)'(i)) begin $error("bit %0d: out=%0d expected %0d", i, out, i); fail_cnt++; end
      else pass_cnt++;
    end

    // All ones: lowest bit (0) should win
    in = '1; #1;
    if (out !== 0 || !valid) begin $error("All-1: out=%0d valid=%0b", out, valid); fail_cnt++; end
    else pass_cnt++;

    // Multiple bits: bit 2 and 5 set, expect 2
    in = 8'b00100100; #1;
    if (out !== 2 || !valid) begin $error("Multi: out=%0d expected 2", out); fail_cnt++; end
    else pass_cnt++;

    $display("priority_encoder_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt == 0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
endmodule
