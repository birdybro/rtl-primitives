`timescale 1ns/1ps
module pipeline_join_tb;
  parameter int DW=8, NI=3;
  logic clk, rst_n;
  logic [NI-1:0] in_valid, in_ready;
  logic [NI-1:0][DW-1:0] in_data;
  logic out_valid, out_ready;
  logic [NI-1:0][DW-1:0] out_data;
  int pass_cnt=0, fail_cnt=0;

  pipeline_join #(.DATA_WIDTH(DW), .NUM_INPUTS(NI)) dut (.*);

  initial clk=0; always #5 clk=~clk;
  task automatic tick; @(posedge clk); #1; endtask

  initial begin
    $dumpfile("pipeline_join_tb.vcd");
    $dumpvars(0, pipeline_join_tb);
    rst_n=0; in_valid=0; in_data=0; out_ready=0;
    tick; tick; rst_n=1;

    // Only some inputs valid: out_valid=0
    in_valid=NI'(3'b011); // inputs 0 and 1, not 2
    in_data[0]=8'hA1; in_data[1]=8'hA2; in_data[2]=8'hA3;
    out_ready=1; #1;
    if (out_valid) begin $error("out_valid=1 with partial inputs"); fail_cnt++; end
    else pass_cnt++;

    // All inputs valid + downstream ready: join fires
    in_valid=NI'('1); out_ready=1; #1;
    if (!out_valid) begin $error("out_valid=0 when all inputs valid"); fail_cnt++; end
    else pass_cnt++;
    // Check all outputs present
    for (int k=0; k<NI; k++) begin
      if (out_data[k] !== DW'(8'hA0+k+1)) begin
        $error("out_data[%0d]=%0h expected %0h", k, out_data[k], 8'hA0+k+1); fail_cnt++;
      end else pass_cnt++;
    end
    // in_ready should be asserted for all
    if (in_ready !== NI'('1)) begin $error("in_ready=%0b expected all-1", in_ready); fail_cnt++; end
    else pass_cnt++;

    // No downstream ready: in_ready=0 even with all valid
    out_ready=0; #1;
    if (|in_ready) begin $error("in_ready asserted without out_ready"); fail_cnt++; end
    else pass_cnt++;

    $display("pipeline_join_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt==0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
  initial begin #5000; $error("Timeout"); $finish; end
endmodule
