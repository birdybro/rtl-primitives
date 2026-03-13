`timescale 1ns/1ps
module reset_synchronizer_tb;
  logic clk, async_rst_n, sync_rst_n;
  int pass_cnt = 0, fail_cnt = 0;

  reset_synchronizer #(.STAGES(2)) dut (.clk(clk), .async_rst_n(async_rst_n), .sync_rst_n(sync_rst_n));

  initial clk = 0; always #5 clk = ~clk;
  task automatic tick; @(posedge clk); #1; endtask

  initial begin
    $dumpfile("reset_synchronizer_tb.vcd");
    $dumpvars(0, reset_synchronizer_tb);
    async_rst_n = 0;
    tick; tick;

    // With async_rst_n=0, sync_rst_n should be 0
    if (sync_rst_n !== 1'b0) begin $error("sync_rst_n=%0b expected 0 while async_rst_n=0", sync_rst_n); fail_cnt++; end
    else pass_cnt++;

    // Release async reset - sync_rst_n should deassert after STAGES cycles
    async_rst_n = 1;
    tick; // cycle 1: FF chain starts filling with 1s
    if (sync_rst_n !== 1'b0) begin $error("sync_rst_n=%0b expected 0 after 1 cycle", sync_rst_n); fail_cnt++; end
    else pass_cnt++;
    tick; // cycle 2: 2-stage sync should now propagate
    if (sync_rst_n !== 1'b1) begin $error("sync_rst_n=%0b expected 1 after 2 cycles", sync_rst_n); fail_cnt++; end
    else pass_cnt++;

    // Assert async reset mid-run: sync_rst_n goes low immediately
    tick; tick;
    async_rst_n = 0; #1;
    if (sync_rst_n !== 1'b0) begin $error("sync_rst_n=%0b expected 0 on async assert", sync_rst_n); fail_cnt++; end
    else pass_cnt++;

    // Release again
    @(posedge clk); async_rst_n = 1;
    tick; tick;
    if (sync_rst_n !== 1'b1) begin $error("sync_rst_n=%0b expected 1 after release", sync_rst_n); fail_cnt++; end
    else pass_cnt++;

    $display("reset_synchronizer_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt == 0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
  initial begin #10000; $error("Timeout"); $finish; end
endmodule
