`timescale 1ns/1ps
module bitmask_generator_tb;
  parameter int W = 8;
  logic [$clog2(W)-1:0]   offset;
  logic [$clog2(W+1)-1:0] len;
  logic [W-1:0]           mask;
  int pass_cnt=0, fail_cnt=0;

  bitmask_generator #(.WIDTH(W)) dut (.offset(offset), .len(len), .mask(mask));

  task automatic check(int off, int l, logic [W-1:0] exp);
    offset=$clog2(W)'(off); len=$clog2(W+1)'(l); #1;
    if (mask !== exp) begin $error("off=%0d len=%0d mask=%08b exp=%08b", off, l, mask, exp); fail_cnt++; end
    else pass_cnt++;
  endtask

  initial begin
    $dumpfile("bitmask_generator_tb.vcd");
    $dumpvars(0, bitmask_generator_tb);

    check(0, 0, 8'b0000_0000); // zero length
    check(0, 1, 8'b0000_0001); // 1 bit at 0
    check(0, 4, 8'b0000_1111); // 4 bits from 0
    check(0, 8, 8'b1111_1111); // full width
    check(2, 4, 8'b0011_1100); // 4 bits from offset 2
    check(4, 4, 8'b1111_0000); // 4 bits from offset 4
    check(7, 1, 8'b1000_0000); // MSB only
    check(3, 1, 8'b0000_1000); // single bit at 3

    $display("bitmask_generator_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt==0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
endmodule
