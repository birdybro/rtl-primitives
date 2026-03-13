`timescale 1ns/1ps
module thermometer_encoder_tb;
  parameter int OW = 8;
  logic [$clog2(OW+1)-1:0] in;
  logic [OW-1:0] out;
  int pass_cnt = 0, fail_cnt = 0;

  thermometer_encoder #(.OUT_WIDTH(OW)) dut (.in(in), .out(out));

  task automatic check(int n, logic [OW-1:0] exp);
    in = $clog2(OW+1)'(n); #1;
    if (out !== exp) begin $error("in=%0d out=%08b expected %08b", n, out, exp); fail_cnt++; end
    else pass_cnt++;
  endtask

  initial begin
    $dumpfile("thermometer_encoder_tb.vcd");
    $dumpvars(0, thermometer_encoder_tb);

    check(0, 8'b0000_0000);
    check(1, 8'b0000_0001);
    check(2, 8'b0000_0011);
    check(3, 8'b0000_0111);
    check(4, 8'b0000_1111);
    check(5, 8'b0001_1111);
    check(6, 8'b0011_1111);
    check(7, 8'b0111_1111);
    check(8, 8'b1111_1111);

    // Verify bit count matches input N
    for (int n = 0; n <= OW; n++) begin
      in = $clog2(OW+1)'(n); #1;
      if ($countones(out) !== n) begin
        $error("n=%0d: %0d bits set expected %0d", n, $countones(out), n); fail_cnt++;
      end else pass_cnt++;
    end

    $display("thermometer_encoder_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt == 0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
endmodule
