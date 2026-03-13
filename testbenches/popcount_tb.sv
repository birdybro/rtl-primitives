`timescale 1ns/1ps
module popcount_tb;
  parameter int W = 8;
  logic [W-1:0]            in;
  logic [$clog2(W+1)-1:0]  count;
  int pass_cnt = 0, fail_cnt = 0;

  popcount #(.WIDTH(W)) dut (.in(in), .count(count));

  function automatic int ref_popcount(logic [W-1:0] v);
    int c = 0;
    for (int i = 0; i < W; i++) if (v[i]) c++;
    return c;
  endfunction

  initial begin
    $dumpfile("popcount_tb.vcd");
    $dumpvars(0, popcount_tb);

    for (int i = 0; i <= 255; i++) begin
      int exp;
      in = W'(i); #1;
      exp = ref_popcount(W'(i));
      if (count !== $clog2(W+1)'(exp)) begin
        $error("in=%08b count=%0d expected=%0d", in, count, exp);
        fail_cnt++;
      end else pass_cnt++;
    end

    $display("popcount_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt == 0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
endmodule
