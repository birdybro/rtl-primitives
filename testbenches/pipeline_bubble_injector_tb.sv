`timescale 1ns/1ps
module pipeline_bubble_injector_tb;
  parameter int DW = 8;
  logic clk, rst_n, in_valid, inject_bubble, out_valid;
  logic [DW-1:0] in_data, out_data;
  int pass_cnt = 0, fail_cnt = 0;

  pipeline_bubble_injector #(.DATA_WIDTH(DW)) dut (
    .clk(clk), .rst_n(rst_n),
    .in_valid(in_valid), .in_data(in_data),
    .inject_bubble(inject_bubble),
    .out_valid(out_valid), .out_data(out_data));

  initial clk=0; always #5 clk=~clk;
  task automatic tick; @(posedge clk); #1; endtask

  initial begin
    $dumpfile("pipeline_bubble_injector_tb.vcd");
    $dumpvars(0, pipeline_bubble_injector_tb);
    rst_n=0; in_valid=0; in_data=0; inject_bubble=0;
    tick; tick; rst_n=1;

    // Pass-through: no bubble
    in_valid=1; in_data=8'hA5; inject_bubble=0; #1;
    if (!out_valid) begin $error("out_valid=0 without bubble"); fail_cnt++; end
    else pass_cnt++;
    if (out_data !== 8'hA5) begin $error("out_data=%0h expected A5", out_data); fail_cnt++; end
    else pass_cnt++;

    // Inject bubble: squash beat
    in_valid=1; in_data=8'hB5; inject_bubble=1; #1;
    if (out_valid) begin $error("out_valid=1 during bubble"); fail_cnt++; end
    else pass_cnt++;
    if (out_data !== '0) begin $error("out_data=%0h expected 0 (NOP) during bubble", out_data); fail_cnt++; end
    else pass_cnt++;

    // Remove bubble: data passes again
    inject_bubble=0; #1;
    if (!out_valid) begin $error("out_valid=0 after bubble removed"); fail_cnt++; end
    else pass_cnt++;
    if (out_data !== 8'hB5) begin $error("out_data=%0h expected B5", out_data); fail_cnt++; end
    else pass_cnt++;

    // in_valid=0: out_valid=0 regardless
    in_valid=0; inject_bubble=0; #1;
    if (out_valid) begin $error("out_valid=1 when in_valid=0"); fail_cnt++; end
    else pass_cnt++;

    $display("pipeline_bubble_injector_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt==0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
  initial begin #5000; $error("Timeout"); $finish; end
endmodule
