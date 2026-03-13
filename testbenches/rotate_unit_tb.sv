`timescale 1ns/1ps
module rotate_unit_tb;
  parameter int W = 8;
  logic [W-1:0] in, out;
  logic [$clog2(W)-1:0] rot_amt;
  logic dir;
  int pass_cnt = 0, fail_cnt = 0;

  rotate_unit #(.WIDTH(W)) dut (.in(in), .rot_amt(rot_amt), .dir(dir), .out(out));

  task automatic check(
    input logic [W-1:0] i,
    input logic [$clog2(W)-1:0] amt,
    input logic d,
    input logic [W-1:0] exp
  );
    in=i; rot_amt=amt; dir=d; #1;
    if (out !== exp) begin
      $error("in=%08b amt=%0d dir=%0b -> out=%08b exp=%08b", i, amt, d, out, exp);
      fail_cnt++;
    end else pass_cnt++;
  endtask

  initial begin
    $dumpfile("rotate_unit_tb.vcd");
    $dumpvars(0, rotate_unit_tb);

    // Rotate left by 0: no change
    check(8'b1010_0001, 0, 0, 8'b1010_0001);
    // Rotate left by 1
    check(8'b1000_0001, 1, 0, 8'b0000_0011);
    // Rotate left by 7 = same as rotate right by 1
    check(8'b1000_0001, 7, 0, 8'b1100_0000);
    // Rotate right by 0: no change
    check(8'b1010_0001, 0, 1, 8'b1010_0001);
    // Rotate right by 1
    check(8'b1000_0001, 1, 1, 8'b1100_0000);
    // Rotate right by 4
    check(8'b1111_0000, 4, 1, 8'b0000_1111);
    // Rotate left by 4
    check(8'b1111_0000, 4, 0, 8'b0000_1111);
    // Rotate left by 3
    check(8'b0000_0001, 3, 0, 8'b0000_1000);
    // Rotate right by 3
    check(8'b0000_1000, 3, 1, 8'b0000_0001);

    $display("rotate_unit_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt == 0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
endmodule
