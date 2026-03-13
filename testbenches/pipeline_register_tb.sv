`timescale 1ns/1ps
module pipeline_register_tb;
  parameter int DW=8;
  logic clk, rst_n, en, flush;
  logic [DW-1:0] din, dout;
  logic valid_in, valid_out;
  int pass_cnt=0, fail_cnt=0;

  pipeline_register #(.DATA_WIDTH(DW)) dut (.*);

  initial clk=0; always #5 clk=~clk;
  task automatic tick; @(posedge clk); #1; endtask

  initial begin
    $dumpfile("pipeline_register_tb.vcd");
    $dumpvars(0, pipeline_register_tb);
    rst_n=0; en=0; flush=0; din=0; valid_in=0;
    tick; tick; rst_n=1;

    // After reset dout=0, valid_out=0
    if (dout!==0 || valid_out!==0) begin $error("Reset: dout=%0h valid=%0b", dout, valid_out); fail_cnt++; end
    else pass_cnt++;

    // Normal enable: data and valid propagate
    en=1; din=8'hAA; valid_in=1; tick;
    if (dout!==8'hAA || !valid_out) begin $error("Enable: dout=%0h valid=%0b", dout, valid_out); fail_cnt++; end
    else pass_cnt++;

    // Disable: output holds
    en=0; din=8'hBB; valid_in=0; tick;
    if (dout!==8'hAA) begin $error("Hold: dout=%0h expected AA", dout); fail_cnt++; end
    else pass_cnt++;

    // Flush: clears output
    en=1; flush=1; tick; flush=0;
    if (dout!==0 || valid_out!==0) begin $error("Flush: dout=%0h valid=%0b", dout, valid_out); fail_cnt++; end
    else pass_cnt++;

    // valid_in=0 propagates valid_out=0
    en=1; din=8'h55; valid_in=0; tick;
    if (valid_out!==0) begin $error("valid_in=0 but valid_out=%0b", valid_out); fail_cnt++; end
    else pass_cnt++;

    $display("pipeline_register_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt==0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
  initial begin #5000; $error("Timeout"); $finish; end
endmodule
