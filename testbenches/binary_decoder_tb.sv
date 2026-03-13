`timescale 1ns/1ps
module binary_decoder_tb;
  parameter int IW=3, OW=8;
  logic en;
  logic [IW-1:0] in;
  logic [OW-1:0] out;
  int pass_cnt=0, fail_cnt=0;

  binary_decoder #(.IN_WIDTH(IW), .OUT_WIDTH(OW)) dut (.en(en), .in(in), .out(out));

  task automatic check(input logic e, logic [IW-1:0] idx, logic [OW-1:0] exp);
    en=e; in=idx; #1;
    if (out !== exp) begin $error("en=%0b in=%0d out=%08b exp=%08b", e, idx, out, exp); fail_cnt++; end
    else pass_cnt++;
  endtask

  initial begin
    $dumpfile("binary_decoder_tb.vcd");
    $dumpvars(0, binary_decoder_tb);

    // Disabled: all zeros
    check(0, 0, 8'b0000_0000);
    check(0, 3, 8'b0000_0000);

    // Enabled: one-hot decode
    check(1, 0, 8'b0000_0001);
    check(1, 1, 8'b0000_0010);
    check(1, 2, 8'b0000_0100);
    check(1, 3, 8'b0000_1000);
    check(1, 4, 8'b0001_0000);
    check(1, 5, 8'b0010_0000);
    check(1, 6, 8'b0100_0000);
    check(1, 7, 8'b1000_0000);

    $display("binary_decoder_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt==0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
endmodule
