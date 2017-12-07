/******************************************************************************/
/* FIFO design collection                                    Ryohei Kobayashi */
/*                                                         Version 2016-12-07 */
/******************************************************************************/
`default_nettype none

/***** A BlockRAM-based FIFO                                              *****/
/******************************************************************************/
module BFIFO #(parameter                    FIFO_SIZE  =  4,  // size in log scale, 4 for 16 entry
               parameter                    FIFO_WIDTH = 32)  // fifo width in bit
              (input  wire                  CLK, 
               input  wire                  RST, 
               input  wire                  enq, 
               input  wire                  deq, 
               input  wire [FIFO_WIDTH-1:0] din, 
               output reg  [FIFO_WIDTH-1:0] dot, 
               output wire                  emp, 
               output wire                  full, 
               output reg  [FIFO_SIZE:0]    cnt);
  
  reg [FIFO_SIZE-1:0]  head, tail;
  reg [FIFO_WIDTH-1:0] mem [(1<<FIFO_SIZE)-1:0];

  assign emp  = (cnt==0);
  assign full = (cnt==(1<<FIFO_SIZE));
  
  always @(posedge CLK) dot <= mem[head];
  
  always @(posedge CLK) begin
    if (RST) {cnt, head, tail} <= 0;
    else begin
      case ({enq, deq})
        2'b01: begin                 head<=head+1;               cnt<=cnt-1; end
        2'b10: begin mem[tail]<=din;               tail<=tail+1; cnt<=cnt+1; end
        2'b11: begin mem[tail]<=din; head<=head+1; tail<=tail+1;             end
      endcase
    end
  end
endmodule


/***** A Distributed RAM-based FIFO                                       *****/
/******************************************************************************/
module DFIFO #(parameter                    FIFO_SIZE  =  4,  // size in log scale, 4 for 16 entry
               parameter                    FIFO_WIDTH = 32)  // fifo width in bit
              (input  wire                  CLK, 
               input  wire                  RST, 
               input  wire                  enq, 
               input  wire                  deq, 
               input  wire [FIFO_WIDTH-1:0] din, 
               output wire [FIFO_WIDTH-1:0] dot, 
               output wire                  emp, 
               output wire                  full, 
               output reg  [FIFO_SIZE:0]    cnt);
  
  reg [FIFO_SIZE-1:0]  head, tail;
  reg [FIFO_WIDTH-1:0] mem [(1<<FIFO_SIZE)-1:0];

  assign emp  = (cnt==0);
  assign full = (cnt==(1<<FIFO_SIZE));
  assign dot  = mem[head];
  
  always @(posedge CLK) begin
    if (RST) {cnt, head, tail} <= 0;
    else begin
      case ({enq, deq})
        2'b01: begin                 head<=head+1;               cnt<=cnt-1; end
        2'b10: begin mem[tail]<=din;               tail<=tail+1; cnt<=cnt+1; end
        2'b11: begin mem[tail]<=din; head<=head+1; tail<=tail+1;             end
      endcase
    end
  end
endmodule


/***** An SRL(Shift Register LUT)-based FIFO                              *****/
/******************************************************************************/
module SRL_FIFO #(parameter                    FIFO_SIZE  = 4,   // size in log scale, 4 for 16 entry
                  parameter                    FIFO_WIDTH = 32)  // fifo width in bit
                 (input  wire                  CLK,
                  input  wire                  RST,
                  input  wire                  enq,
                  input  wire                  deq,
                  input  wire [FIFO_WIDTH-1:0] din,
                  output wire [FIFO_WIDTH-1:0] dot,
                  output wire                  emp,
                  output wire                  full,
                  output reg  [FIFO_SIZE:0]    cnt);

  reg  [FIFO_SIZE-1:0]  head;
  reg  [FIFO_WIDTH-1:0] mem [(1<<FIFO_SIZE)-1:0];
  
  assign emp  = (cnt==0);
  assign full = (cnt==(1<<FIFO_SIZE));
  assign dot  = mem[head];
    
  always @(posedge CLK) begin
    if (RST) begin
      cnt  <= 0;
      head <= {(FIFO_SIZE){1'b1}};
    end else begin
      case ({enq, deq})
        2'b01: begin cnt <= cnt - 1; head <= head - 1; end
        2'b10: begin cnt <= cnt + 1; head <= head + 1; end
      endcase
    end
  end

  integer i;
  always @(posedge CLK) begin
    if (enq) begin
      mem[0] <= din;
      for (i=1; i<(1<<FIFO_SIZE); i=i+1) mem[i] <= mem[i-1];
    end
  end
  
endmodule

`default_nettype wire
