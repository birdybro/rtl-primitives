`timescale 1ns/1ps
module gray_pointer_sync_tb;
  parameter int AW = 4;
  logic clk, rst_n;
  logic [AW:0] gray_ptr_in, gray_ptr_out;
  int pass_cnt = 0, fail_cnt = 0;

  gray_pointer_sync #(.ADDR_WIDTH(AW)) dut (
    .gray_ptr_in(gray_ptr_in), .gray_ptr_out(gray_ptr_out),
    .clk(clk), .rst_n(rst_n));

  initial clk = 0; always #5 clk = ~clk;
  task automatic tick; @(posedge clk); #1; endtask

  // Convert binary to Gray
  function automatic logic [AW:0] to_gray(input logic [AW:0] bin);
    return bin ^ (bin >> 1);
  endfunction

  initial begin
    $dumpfile("gray_pointer_sync_tb.vcd");
    $dumpvars(0, gray_pointer_sync_tb);
    rst_n=0; gray_ptr_in=0;
    tick; tick; rst_n=1;

    // After reset output should be 0
    tick;
    if (gray_ptr_out !== 0) begin $error("After reset gray_ptr_out=%0h", gray_ptr_out); fail_cnt++; end
    else pass_cnt++;

    // Walk through a sequence of Gray-coded pointer values
    for (int i = 0; i < 8; i++) begin
      logic [AW:0] g;
      g = to_gray(AW+1'(i));
      gray_ptr_in = g;
      tick; tick; tick; // allow 2-FF synchronizer settling
      if (gray_ptr_out !== g) begin
        $error("ptr[%0d]: in=%0h out=%0h", i, g, gray_ptr_out); fail_cnt++;
      end else pass_cnt++;
    end

    // Reset clears output
    rst_n=0; tick; rst_n=1; tick;
    if (gray_ptr_out !== 0) begin $error("After reset gray_ptr_out=%0h expected 0", gray_ptr_out); fail_cnt++; end
    else pass_cnt++;

    $display("gray_pointer_sync_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt == 0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
  initial begin #10000; $error("Timeout"); $finish; end
endmodule
