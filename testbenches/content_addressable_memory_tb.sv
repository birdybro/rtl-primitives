`timescale 1ns/1ps
module content_addressable_memory_tb;
  parameter int DW=8, DEPTH=8;
  logic clk, rst_n;
  logic wr_en, wr_valid_bit, hit;
  logic [$clog2(DEPTH)-1:0] wr_addr, hit_addr;
  logic [DW-1:0] wr_data, search_key;
  int pass_cnt=0, fail_cnt=0;

  content_addressable_memory #(.DATA_WIDTH(DW), .DEPTH(DEPTH)) dut (.*);

  initial clk=0; always #5 clk=~clk;
  task automatic tick; @(posedge clk); #1; endtask

  initial begin
    $dumpfile("content_addressable_memory_tb.vcd");
    $dumpvars(0, content_addressable_memory_tb);
    rst_n=0; wr_en=0; wr_addr=0; wr_data=0; wr_valid_bit=0; search_key=0;
    tick; tick; rst_n=1;

    // After reset: no hits
    search_key=8'hAA; #1;
    if (hit) begin $error("hit asserted after reset"); fail_cnt++; end
    else pass_cnt++;

    // Write entry at addr 2
    wr_en=1; wr_addr=2; wr_data=8'hAA; wr_valid_bit=1; tick; wr_en=0;

    // Search for 8'hAA
    search_key=8'hAA; #1;
    if (!hit) begin $error("no hit for written key"); fail_cnt++; end
    else pass_cnt++;
    if (hit_addr !== 2) begin $error("hit_addr=%0d expected 2", hit_addr); fail_cnt++; end
    else pass_cnt++;

    // Search for non-existent key
    search_key=8'hBB; #1;
    if (hit) begin $error("hit for non-existent key"); fail_cnt++; end
    else pass_cnt++;

    // Write another entry, verify priority (lower addr wins)
    wr_en=1; wr_addr=1; wr_data=8'hAA; wr_valid_bit=1; tick; wr_en=0;
    search_key=8'hAA; #1;
    if (hit_addr !== 1) begin $error("hit_addr=%0d expected 1 (lower priority)", hit_addr); fail_cnt++; end
    else pass_cnt++;

    // Invalidate entry at addr 1
    wr_en=1; wr_addr=1; wr_data=8'hAA; wr_valid_bit=0; tick; wr_en=0;
    search_key=8'hAA; #1;
    if (!hit) begin $error("no hit after invalidating addr 1 (addr 2 still valid)"); fail_cnt++; end
    else pass_cnt++;
    if (hit_addr !== 2) begin $error("hit_addr=%0d expected 2 after invalidating 1", hit_addr); fail_cnt++; end
    else pass_cnt++;

    $display("content_addressable_memory_tb: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt==0) $display("OVERALL: PASS"); else $display("OVERALL: FAIL");
    $finish;
  end
  initial begin #5000; $error("Timeout"); $finish; end
endmodule
