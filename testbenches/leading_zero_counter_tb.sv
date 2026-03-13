`timescale 1ns/1ps
module leading_zero_counter_tb;
  parameter int W = 8;
  logic [W-1:0] in;
  logic [$clog2(W+1)-1:0] count;
  logic all_zero;
  int pass_cnt = 0, fail_cnt = 0;

  leading_zero_counter #(.WIDTH(W)) dut (.in(in), .count(count), .all_zero(all_zero));

  task automatic check(input logic [W-1:0] val, int exp_cnt, logic exp_az);
    in = val; #1;
    if (count !== $clog2(W+1)'(exp_cnt)) begin
      $error("in=%08b count=%0d expected %0d", val, count, exp_cnt); fail_cnt++;
    end else pass_cnt++;
    if (all_zero !== exp_az) begin
      $error("in=%08b all_zero=%0b expected %0b", val, all_zero, exp_az); fail_cnt++;
    end else pass_cnt++;
  endtask

  initial begin
    $dumpfile("leading_zero_counter_tb.vcd");
    $dumpvars(0, leading_zero_counter_tb);

    check(8'b0000_0000, 8, 1'b1); // all zero
    check(8'b1000_0000, 0, 1'b0); // MSB set
    check(8'b0100_0000, 1, 1'b0);
    check(8'b0010_0000, 2, 1'b0);
    check(8'b0001_0000, 3, 1'b0);
    check(8'b0000_1000, 4, 1'b0);
    check(8'b0000_0100, 5, 1'b0);
    check(8'b0000_0010, 6, 1'b0);
    check(8'b0000_0001, 7, 1'b0); // LSB only
    check(8'b1111_1111, 0, 1'b0);
    check(8'b0001_0101, 3, 1'b0); // multiple bits

    $display("leading_zero_counter_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt == 0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
endmodule
