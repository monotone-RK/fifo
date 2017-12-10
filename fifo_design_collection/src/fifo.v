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


/*****  A multi-channel FIFO                                              *****/
/******************************************************************************/
module MULTI_CHANNEL_FIFO #(parameter                    C_LOG      = 2,  // # of channels in log scale
                            parameter                    FIFO_SIZE  = 2,  // FIFO depth of each channel in log scale
                            parameter                    FIFO_WIDTH = 32)
                           (input  wire                  CLK,
                            input  wire                  RST,
                            input  wire                  enq,
                            input  wire [C_LOG-1:0]      enq_idx,
                            input  wire                  deq,
                            input  wire [C_LOG-1:0]      deq_idx,
                            input  wire [FIFO_WIDTH-1:0] din,
                            output reg  [FIFO_WIDTH-1:0] dot,
                            output wire [(1<<C_LOG)-1:0] emp,
                            output wire [(1<<C_LOG)-1:0] full);

  // FIFO_SIZE-1 -> FIFO_SIZE (to generate emp and full)
  reg [FIFO_SIZE:0] head_list [(1<<C_LOG)-1:0];
  reg [FIFO_SIZE:0] tail_list [(1<<C_LOG)-1:0];

  reg [FIFO_WIDTH-1:0] mem [(1<<(C_LOG+FIFO_SIZE))-1:0];
     
  genvar i;
  generate
    for (i=0; i<(1<<C_LOG); i=i+1) begin: channels
      assign emp[i]  = (head_list[i] == tail_list[i]);
      assign full[i] = (head_list[i] == {~tail_list[i][FIFO_SIZE], tail_list[i][FIFO_SIZE-1:0]});
    end
  endgenerate
  
  wire [(C_LOG+FIFO_SIZE)-1:0] raddr = {deq_idx, head_list[deq_idx][FIFO_SIZE-1:0]};
  wire [(C_LOG+FIFO_SIZE)-1:0] waddr = {enq_idx, tail_list[enq_idx][FIFO_SIZE-1:0]};
  
  always @(posedge CLK) dot <= mem[raddr];

  integer p;
  always @(posedge CLK) begin
    if (RST) begin
      for (p=0; p<(1<<C_LOG); p=p+1) begin
        head_list[p] <= 0; 
        tail_list[p] <= 0;
      end
    end else begin
      case ({enq, deq})
        2'b01: begin 
          head_list[deq_idx] <= head_list[deq_idx] + 1;
        end
        2'b10: begin 
          mem[waddr]         <= din;
          tail_list[enq_idx] <= tail_list[enq_idx] + 1; 
        end
        2'b11: begin 
          mem[waddr]         <= din; 
          head_list[deq_idx] <= head_list[deq_idx] + 1; 
          tail_list[enq_idx] <= tail_list[enq_idx] + 1; 
        end
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
