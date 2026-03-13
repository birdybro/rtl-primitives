`timescale 1ns/1ps
module onehot_decoder_tb;
  parameter int IW = 3, OW = 8;
  logic [IW-1:0] in;
  logic [OW-1:0] out;
  int pass_cnt = 0, fail_cnt = 0;

  onehot_decoder #(.IN_WIDTH(IW), .OUT_WIDTH(OW)) dut (.in(in), .out(out));

  task automatic check(input logic [IW-1:0] idx, logic [OW-1:0] exp);
    in = idx; #1;
    if (out !== exp) begin $error("in=%0d out=%08b expected %08b", idx, out, exp); fail_cnt++; end
    else pass_cnt++;
  endtask

  initial begin
    $dumpfile("onehot_decoder_tb.vcd");
    $dumpvars(0, onehot_decoder_tb);

    // Test each position
    for (int i = 0; i < OW; i++) begin
      check(IW'(i), OW'(1 << i));
    end

    // Verify only one bit set for each valid input
    for (int i = 0; i < OW; i++) begin
      in = IW'(i); #1;
      if ($countones(out) !== 1) begin
        $error("in=%0d: %0d bits set expected 1", i, $countones(out)); fail_cnt++;
      end else pass_cnt++;
    end

    $display("onehot_decoder_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt == 0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
endmodule
