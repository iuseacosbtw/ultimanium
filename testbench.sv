`timescale 1ns/1ps
// To stop execution, have the CPU execute 'F0 FF' (OUT 0xFF)

module testbench;
  
  reg [7:0] in;
  reg reset,clk,write;
  wire [7:0] out;
  wire outOn;
  reg [7:0] code [0:255];
  
  top ohmypc(
    .in(in),
    .write(write),
    .reset(reset),
    .clk(clk),
    .out(out),
    .outOn(outOn)
  );
  
  always #5 clk=~clk;
  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, testbench);
    reset=1;
    write=1;
    clk=0;
    $readmemh("code.txt",code);
    for (integer i=0;i<256;i++) begin
      in<=code[i];
      @(negedge clk);
    end
    $display("Wrote code");
    reset=0;
    #5
    reset=1;
    write=0;
    #100000
    $display("Time limit reached.");
    $finish();
  end
  always @(posedge outOn) begin
    if (out==8'b11111111) begin
      $display("CPU requested exit.");
      $finish();
    end else begin
      $display("CPU printed '0x%h (%d,%c)'.",out[7:0],out[7:0],out[7:0]);
    end
  end
  
endmodule
