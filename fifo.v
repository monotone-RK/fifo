`timescale 1ns / 1ps
`default_nettype none
  
`define CLKIN_HALF_PERIOD 5    //100MHz input clock
`define RESET_TIME        1000
`define WIDTH             32   // data width
`define DEPTH             5    // fifo depth
`define W_CNT             3    // counter width
`define W_POS             3    // pointer width for DEPTH
`define HALT_CYCLE        30
module test;
  parameter VCD = "uut.vcd";
    
  /* input */
  reg  CLK;
  reg  RST_X;
  wire ENQ;
  wire DEQ;
  wire [`WIDTH-1:0] DIN;
  
  /* output */
  wire [`WIDTH-1:0] DOUT;
  wire EMPTY;
  wire FULL;

  FIFO #(.WIDTH(`WIDTH), .DEPTH(`DEPTH), .W_CNT(`W_CNT), .W_POS(`W_POS))
  fifo(CLK, RST_X, ENQ, DEQ, DIN, DOUT, EMPTY, FULL);
  
  initial begin
    CLK = 0;
    forever #(`CLKIN_HALF_PERIOD) CLK = ~CLK;
  end
  initial begin
    RST_X = 0;
    #`RESET_TIME;
    RST_X = 1;
  end
  initial begin
    $dumpfile(VCD);
    $dumpvars(0, fifo);
  end

  reg [`WIDTH-1:0] cycle;
  assign DIN = cycle;
  assign ENQ = (cycle<20) && !FULL;
  assign DEQ = (cycle%2)  && !EMPTY;

  always @(posedge CLK) begin
    if (!RST_X) begin
	 cycle <= 0;
    end else begin
	 cycle <= cycle + 1;
	 $write("cycle(DIN): %d DOUT: %d ENQ: %d DEQ: %d EMPTY %d FULL %d\n", 
		   cycle, DOUT, ENQ, DEQ, EMPTY, FULL);
	 if (cycle == `HALT_CYCLE) $finish;
    end
  end
endmodule

module FIFO(CLK, RST_X, ENQ, DEQ, DIN, DOUT, EMPTY, FULL);
  parameter WIDTH = 32; // data width
  parameter DEPTH = 4;  // fifo depth
  parameter W_CNT = 3;  // counter width
  parameter W_POS = 2;  // pointer width for DEPTH
  
  input                  CLK;
  input                  RST_X;
  input                  ENQ;
  input                  DEQ;
  input      [WIDTH-1:0] DIN;  
  output reg [WIDTH-1:0] DOUT;
  output                 EMPTY;
  output                 FULL;

  reg [WIDTH-1:0] mem[DEPTH-1:0];
  reg [W_CNT-1:0] cnt;
  reg [W_POS-1:0] head;
  reg [W_POS-1:0] tail;
	  
  assign EMPTY = (cnt == 0);
  assign FULL  = (cnt == DEPTH);

  always @(posedge CLK) begin
    if (!RST_X) begin
	 DOUT <= 0;
	 cnt  <= 0;
	 head <= 0;
	 tail <= 0;
    end else begin
	 if (ENQ && !FULL) begin  
	   mem[tail] <= DIN;
	   tail      <= (tail+1) % DEPTH;
	 end
	 if (DEQ && !EMPTY) begin 
	   DOUT <= mem[head];
	   head <= (head+1) % DEPTH;
	 end else begin
	   DOUT <= 0;
	 end
	 cnt <= ((ENQ && !FULL) && !(DEQ && !EMPTY)) ? cnt + 1 :
             (!(ENQ && !FULL) && (DEQ && !EMPTY)) ? cnt - 1 : cnt;
    end
  end
endmodule  
`default_nettype wire
