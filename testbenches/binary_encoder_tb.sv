`timescale 1ns/1ps
module binary_encoder_tb;
  parameter int IW=3, OW=8;
  logic [IW-1:0] bin_in;
  logic [OW-1:0] onehot_out;
  int pass_cnt=0, fail_cnt=0;

  binary_encoder #(.IN_WIDTH(IW), .OUT_WIDTH(OW)) dut (.bin_in(bin_in), .onehot_out(onehot_out));

  task automatic check(input logic [IW-1:0] idx, logic [OW-1:0] exp);
    bin_in=idx; #1;
    if (onehot_out !== exp) begin $error("in=%0d out=%08b exp=%08b", idx, onehot_out, exp); fail_cnt++; end
    else pass_cnt++;
  endtask

  initial begin
    $dumpfile("binary_encoder_tb.vcd");
    $dumpvars(0, binary_encoder_tb);

    // Binary index -> one-hot
    check(0, 8'b0000_0001);
    check(1, 8'b0000_0010);
    check(2, 8'b0000_0100);
    check(3, 8'b0000_1000);
    check(4, 8'b0001_0000);
    check(5, 8'b0010_0000);
    check(6, 8'b0100_0000);
    check(7, 8'b1000_0000);

    // Verify only one bit set
    for (int i=0; i<OW; i++) begin
      bin_in=IW'(i); #1;
      if ($countones(onehot_out)!==1) begin $error("in=%0d: %0d bits set", i, $countones(onehot_out)); fail_cnt++; end
      else pass_cnt++;
    end

    $display("binary_encoder_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt==0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
endmodule
