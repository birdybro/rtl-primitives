`timescale 1ns/1ps
module pipeline_fork_tb;
  parameter int DW=8, NO=3;
  logic clk, rst_n, in_valid, in_ready;
  logic [DW-1:0] in_data;
  logic [NO-1:0] out_valid, out_ready;
  logic [NO-1:0][DW-1:0] out_data;
  int pass_cnt=0, fail_cnt=0;

  pipeline_fork #(.DATA_WIDTH(DW), .NUM_OUTPUTS(NO)) dut (.*);

  initial clk=0; always #5 clk=~clk;
  task automatic tick; @(posedge clk); #1; endtask

  initial begin
    $dumpfile("pipeline_fork_tb.vcd");
    $dumpvars(0, pipeline_fork_tb);
    rst_n=0; in_valid=0; in_data=0; out_ready=0;
    tick; tick; rst_n=1;

    // No valid input: no outputs
    in_valid=0; #1;
    if (|out_valid) begin $error("out_valid asserted without in_valid"); fail_cnt++; end
    else pass_cnt++;

    // Present data, accept all outputs simultaneously
    in_valid=1; in_data=8'hA5; out_ready=NO'('1); // all outputs ready
    tick;
    // Verify data reaches all outputs
    for (int k=0; k<NO; k++) begin
      if (out_data[k] !== 8'hA5) begin $error("out_data[%0d]=%0h expected A5", k, out_data[k]); fail_cnt++; end
      else pass_cnt++;
    end
    // in_ready should have pulsed
    if (!in_ready) begin $error("in_ready not asserted when all ready"); fail_cnt++; end
    else pass_cnt++;
    tick;
    in_valid=0; out_ready=0;

    // Staggered acceptance: accept outputs one at a time
    in_valid=1; in_data=8'hB5; out_ready=0;
    tick; // t0: no output accepts
    out_ready[0]=1; tick; out_ready[0]=0; // output 0 accepts
    out_ready[1]=1; tick; out_ready[1]=0; // output 1 accepts
    // in_ready not yet since output 2 hasn't accepted
    out_ready[2]=1; tick; // output 2 accepts -> in_ready fires
    if (!in_ready) begin $error("in_ready not asserted after all accepted"); fail_cnt++; end
    else pass_cnt++;
    out_ready=0; tick;
    in_valid=0;

    $display("pipeline_fork_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt==0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
  initial begin #10000; $error("Timeout"); $finish; end
endmodule
