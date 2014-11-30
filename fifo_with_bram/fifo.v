`timescale 1ns / 1ps
`default_nettype none
  
`define CLKIN_HALF_PERIOD 5    // 100MHz input clock
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

module FIFO #(parameter               WIDTH = 32, // data width
              parameter               DEPTH = 4,  // fifo depth
              parameter               W_CNT = 3,  // counter width
              parameter               W_POS = 2)  // pointer width for DEPTH
             (input  wire             CLK, 
              input  wire             RST_X, 
              input  wire             ENQ, 
              input  wire             DEQ, 
              input  wire [WIDTH-1:0] DIN, 
              output wire [WIDTH-1:0] DOUT, 
              output wire             EMPTY, 
              output wire             FULL);
  
  reg [W_CNT-1:0] cnt;
  reg [W_POS-1:0] head;
  reg [W_POS-1:0] tail;
  reg             dout_en;
  
  wire             re = DEQ && !EMPTY;
  wire             we = ENQ && !FULL;
  wire [WIDTH-1:0] dout;
  
  FIFO_RAM #(.WIDTH(WIDTH), .DEPTH(DEPTH), .W_POS(W_POS))
  fifo_ram(CLK, we, head, tail, DIN, dout);
  
  assign DOUT  = (dout_en) ? dout : 0;
  assign EMPTY = (cnt == 0);
  assign FULL  = (cnt == DEPTH);

  always @(posedge CLK) begin
    if (!RST_X) begin
      cnt    <= 0;
      head   <= 0;
      tail   <= 0;
      dout_en <= 0;
    end else begin
      if (we) tail <= (tail == DEPTH-1) ? 0 : tail+1;
      if (re) head <= (head == DEPTH-1) ? 0 : head+1;
      if (we && re) cnt <= cnt;
      else if (we)  cnt <= cnt + 1;
      else if (re)  cnt <= cnt - 1;
      dout_en <= re;
    end
  end
endmodule

module FIFO_RAM #(parameter               WIDTH = 32, // data width
                  parameter               DEPTH = 4,  // fifo depth
                  parameter               W_POS = 2)  // pointer width for DEPTH
                 (input  wire             CLK,
                  input  wire             WE,
                  input  wire [W_POS-1:0] RADDR,
                  input  wire [W_POS-1:0] WADDR,
                  input  wire [WIDTH-1:0] DIN,
                  output reg  [WIDTH-1:0] DOUT);
  
  reg [WIDTH-1:0] mem [DEPTH-1:0];
  
  always @(posedge CLK) begin
    if (WE) mem[WADDR] <= DIN;
    DOUT <= mem[RADDR];
  end
endmodule

`default_nettype wire
