`timescale 1ns/1ps
module barrel_shifter_tb;
  parameter int W = 8;
  logic [W-1:0]         in, out;
  logic [$clog2(W)-1:0] shift_amt;
  logic dir, arith;
  int pass_cnt = 0, fail_cnt = 0;

  barrel_shifter #(.WIDTH(W)) dut (.in(in), .shift_amt(shift_amt), .dir(dir), .arith(arith), .out(out));

  task automatic check(
    input logic [W-1:0] i, logic [$clog2(W)-1:0] sa,
    input logic d, a, logic [W-1:0] exp
  );
    in=i; shift_amt=sa; dir=d; arith=a; #1;
    if (out !== exp) begin
      $error("in=%08b sa=%0d dir=%0b arith=%0b -> out=%08b exp=%08b", i, sa, d, a, out, exp);
      fail_cnt++;
    end else pass_cnt++;
  endtask

  initial begin
    $dumpfile("barrel_shifter_tb.vcd");
    $dumpvars(0, barrel_shifter_tb);

    // Logical left shift
    check(8'b0000_0001, 3'(0), 0, 0, 8'b0000_0001);
    check(8'b0000_0001, 3'(1), 0, 0, 8'b0000_0010);
    check(8'b0000_0001, 3'(7), 0, 0, 8'b1000_0000);
    check(8'b1010_1010, 3'(2), 0, 0, 8'b1010_1000);

    // Logical right shift
    check(8'b1000_0000, 3'(1), 1, 0, 8'b0100_0000);
    check(8'b1000_0000, 3'(7), 1, 0, 8'b0000_0001);
    check(8'b1010_1010, 3'(2), 1, 0, 8'b0010_1010);

    // Arithmetic right shift (sign extend)
    check(8'b1000_0000, 3'(1), 1, 1, 8'b1100_0000);
    check(8'b1000_0000, 3'(7), 1, 1, 8'b1111_1111);
    check(8'b0100_0000, 3'(1), 1, 1, 8'b0010_0000); // positive no sign extend

    $display("barrel_shifter_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt == 0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
endmodule
