`timescale 1ns/1ps
module delay_line_tb;
  parameter int DW=8, DEPTH=4;
  logic clk, rst_n, en;
  logic [DW-1:0] din, dout;
  logic [DEPTH:0][DW-1:0] tap_out;
  int pass_cnt=0, fail_cnt=0;

  delay_line #(.DATA_WIDTH(DW), .DEPTH(DEPTH)) dut (.*);

  initial clk=0; always #5 clk=~clk;
  task automatic tick; @(posedge clk); #1; endtask

  initial begin
    $dumpfile("delay_line_tb.vcd");
    $dumpvars(0, delay_line_tb);
    rst_n=0; en=0; din=0;
    tick; tick; rst_n=1;

    // tap_out[0] should always equal din (combinational)
    din=8'h42; en=1; #1;
    if (tap_out[0]!==8'h42) begin $error("tap[0]=%0h expected 42", tap_out[0]); fail_cnt++; end
    else pass_cnt++;

    // Push a known word and verify it appears at dout after DEPTH cycles
    din=8'hA5; tick;
    din=8'h00; // send zeros after
    repeat(DEPTH-1) tick;
    // Now dout should have 8'hA5
    if (dout!==8'hA5) begin $error("dout=%0h expected A5 after %0d cycles", dout, DEPTH); fail_cnt++; end
    else pass_cnt++;

    // Verify tap outputs: fill pipeline with incrementing values
    rst_n=0; tick; rst_n=1;
    for (int i=1; i<=DEPTH; i++) begin
      din=DW'(i); en=1; tick;
    end
    // tap_out[DEPTH] = dout = value pushed DEPTH cycles ago = 1
    if (dout!==8'h01) begin $error("After fill dout=%0h expected 01", dout); fail_cnt++; end
    else pass_cnt++;
    // tap_out[0] = current din = DEPTH
    din=DW'(DEPTH+1); #1;
    if (tap_out[0]!==DW'(DEPTH+1)) begin $error("tap[0]=%0h expected %0d", tap_out[0], DEPTH+1); fail_cnt++; end
    else pass_cnt++;

    // en=0 freezes pipeline
    din=8'hFF; en=0; tick;
    if (dout!==8'h01) begin $error("en=0: dout changed to %0h", dout); fail_cnt++; end
    else pass_cnt++;

    $display("delay_line_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt==0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
  initial begin #5000; $error("Timeout"); $finish; end
endmodule
