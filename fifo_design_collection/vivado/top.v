//-----------------------------------------------------------------------------
// File          : top.v
// Author        : Ryohei Kobayashi
// Created       : 08.12.2017
// Last modified : 08.12.2017
//-----------------------------------------------------------------------------
// Description :
// A project file to check what FPGA resource is used for the following FIFOs
//-----------------------------------------------------------------------------
`default_nettype none

`define FIFO_SIZE   4  // size in log scale, 4 for 16 entry
`define FIFO_WIDTH 32  // fifo width in bit

module top(input  wire       CLK,
           input  wire       RST_IN,
           output wire       OUT);

  reg RST; always @(posedge CLK) RST <= RST_IN;
     
  wire                   fifo_enq;
  wire                   fifo_deq;
  reg  [`FIFO_WIDTH-1:0] fifo_din;
  wire [`FIFO_WIDTH-1:0] bfifo_dot;
  wire [`FIFO_WIDTH-1:0] dfifo_dot;
  wire [`FIFO_WIDTH-1:0] srl_fifo_dot;
  wire                   fifo_emp;
  wire                   fifo_ful;
  wire [`FIFO_SIZE:0]    fifo_cnt;

  assign fifo_enq = ~fifo_ful;
  assign fifo_deq = ~fifo_emp;

  BFIFO #(5, `FIFO_WIDTH)
  bfifo(CLK, RST, fifo_enq, fifo_deq, fifo_din, 
        bfifo_dot, fifo_emp, fifo_ful, fifo_cnt);
  DFIFO #(`FIFO_SIZE, `FIFO_WIDTH)
  dfifo(CLK, RST, fifo_enq, fifo_deq, fifo_din, 
        dfifo_dot, 1'b0, 1'b0, 1'b0);
  SRL_FIFO #(`FIFO_SIZE, `FIFO_WIDTH)
  srl_fifo(CLK, RST, fifo_enq, fifo_deq, fifo_din, 
           srl_fifo_dot, 1'b0, 1'b0, 1'b0);

  always @(posedge CLK) begin
    if      (RST)      fifo_din <= 1;
    else if (fifo_enq) fifo_din <= fifo_din + 1;
  end
  
  assign OUT = ^{bfifo_dot, dfifo_dot, srl_fifo_dot};
  
endmodule

`default_nettype wire
