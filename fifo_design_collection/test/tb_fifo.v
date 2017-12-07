/******************************************************************************/
/* A test bench                                              Ryohei Kobayashi */
/*                                                         Version 2017-11-30 */
/******************************************************************************/
`default_nettype none
  
`include "fifo.v"

`define FIFO_SIZE   4  // size in log scale, 4 for 16 entry
`define FIFO_WIDTH 32  // fifo width in bit
  

module tb_FIFO();  // only for DFIFO and SRL_FIFO
  reg CLK; initial begin CLK=0; forever #50 CLK=~CLK; end
  reg RST; initial begin RST=1; #400 RST=0; end

  wire                   fifo_enq;
  wire                   fifo_deq;
  reg  [`FIFO_WIDTH-1:0] fifo_din;
  wire [`FIFO_WIDTH-1:0] fifo_dot;
  wire                   fifo_emp;
  wire                   fifo_ful;
  wire [`FIFO_SIZE:0]    fifo_cnt;

  assign fifo_enq = ~fifo_ful;
  assign fifo_deq = ~fifo_emp;

  DFIFO #(`FIFO_SIZE, `FIFO_WIDTH)
  // SRL_FIFO #(`FIFO_SIZE, `FIFO_WIDTH)
  fifo(CLK, RST, fifo_enq, fifo_deq, fifo_din, 
       fifo_dot, fifo_emp, fifo_ful, fifo_cnt);

  always @(posedge CLK) begin
    if      (RST)      fifo_din <= 1;
    else if (fifo_enq) fifo_din <= fifo_din + 1;
  end

  // error checker
  reg [`FIFO_WIDTH-1:0] chk_data;
  always @(posedge CLK) begin
    if (RST) begin
      chk_data <= 1;
    end else begin
      if (fifo_deq) begin
        chk_data <= chk_data + 1;
        if (fifo_dot != chk_data) begin
          $write("\nError!\n");
          $write("%d %d\n", fifo_dot, chk_data);
          $finish();
        end
      end
    end
  end
  
  // simulation finish condition
  reg [31:0] cycle;
  always @(posedge CLK) begin
    if (RST) begin
      cycle <= 0;
    end else begin
      cycle <= cycle + 1;
      if (cycle >= 100) $finish();
    end
  end

  always @(posedge CLK) begin
    if (fifo_deq) begin
      $write("%d | %d", cycle, fifo_dot);
      $write("\n");
      $fflush();
    end
  end
  
endmodule

`default_nettype wire
