`define READ_CONV_WEIGHTS 0
`define READ_FC_WEIGHTS 1
`define W00 8
`define W01 9 
`define W02 6 
`define W10 7 
`define W11 4 
`define W12 5
`define W20 2 
`define W21 3
`define W22 0
`define ROW_STRIDE 2
`define COL_STRIDE 1


module MyDesign (
//---------------------------------------------------------------------------
//Control signals
  input   wire dut_run                    , 
  output  wire dut_busy                   ,
  input   wire reset_b                    ,  
  input   wire clk                        ,
 
//---------------------------------------------------------------------------
//Input SRAM interface
  output wire               input_sram_write_enable    ,
  output reg        [11:0] input_sram_write_addresss   ,
  output reg        [15:0] input_sram_write_data      ,
  output reg        [11:0] input_sram_read_address    ,
  input wire [15:0] input_sram_read_data       ,

//---------------------------------------------------------------------------
//Output SRAM interface
  output wire       output_sram_write_enable    ,
  output reg [11:0] output_sram_write_addresss   ,
  output wire[15:0] output_sram_write_data      ,
  output reg [11:0] output_sram_read_address    ,
  input wire [15:0] output_sram_read_data       ,

//---------------------------------------------------------------------------
//Scratchpad SRAM interface
  output reg        scratchpad_sram_write_enable    ,
  output reg [11:0] scratchpad_sram_write_addresss   ,
  output reg [15:0] scratchpad_sram_write_data      ,
  output reg [11:0] scratchpad_sram_read_address    ,
  input wire [15:0] scratchpad_sram_read_data       ,

//---------------------------------------------------------------------------
//Weights SRAM interface                                                       
  output reg               weights_sram_write_enable    ,
  output reg        [11:0] weights_sram_write_addresss   ,
  output reg        [15:0] weights_sram_write_data      ,
  output wire       [11:0] weights_sram_read_address    ,
  input wire        [15:0] weights_sram_read_data       

);
//----------------------------------------------------------------------------------------
// REGISTER INSTANTIATIONS
//---------------------------------------------------------------------------------------- 

  reg signed  [7:0]  conv_weights [0:9];
  reg         [6:0]  row, N;
  reg         [5:0]  col;      //Col from 0 to N/2 -1
  reg         [11:0] base_ptr;
  reg   [11:0] addr_conv_weights;

//---------------------------------------------------------------------------
// For Convolution Units 
  reg   [2:0]  iteration_cntr_val;
  reg signed [19:0] accumulators [0:3];
  reg signed [7:0]   Weight_H [0:3];
  reg signed [7:0]   Weight_L [0:3];
  

//---------------------------------------------------------------------------
// For RELU + Max Pooling
  
  reg signed [7:0]   maxPooling_input [0:3];
  reg  [1:0]   val_max_pooling_itr;
  reg                trigger_mp_delayed_1;
  reg                trigger_mp_delayed_3;
  reg signed [7:0]   maxPooling_output [0:1];
  reg [3:1]          matrix_done_flag_delayed;
//----------------------------------------------------------------------------------------
// WIRE INSTANTIATIONS
//---------------------------------------------------------------------------------------- 
//---------------------------------------------------------------------------
// For CONV FSM
  wire           en_weight_reg;                                //FSM should set to 0
  wire         incr_weight_addr;
  wire   [2:0] counter_conv_weights;

  wire   [11:0] addr_fc_weights;
  wire   [3:0]  ACC_Enable;
  wire   [3:0]  ACC_Send;
  wire   [3:0]  ACC_Clear;
  wire          en_col_incr;
  wire          en_addr_incr_mode1;
  wire          en_addr_incr_mode2;
  wire          read_N;
  wire          stop_conv;
  wire          val_incr_base_addr;
  wire          matrix_done_flag;
  wire          reset_datapath_n;
  wire          trigger_fc_fsm;
//---------------------------------------------------------------------------
// For CONV Datapth
  
  wire          en_iteration_cntr;
  wire          iteration_cntr_flag;
  wire          is_last_iteration; 
  wire          reset_reg;
  wire signed [15:0]  mult_H   [0:3];
  wire signed [15:0]  mult_L   [0:3];
//---------------------------------------------------------------------------
// For RELU + Max Pooling
  wire signed [7:0]   maxPooling_compute_H;
  wire signed [7:0]   maxPooling_compute_L;
  wire [7:0]    conv_ReLu [0:3];
  wire          trigger_mp_H;
  wire          trigger_mp_L;
 

//----------------------------------------------------------------------------------------
// RESET SIGNAL GENERATION
//---------------------------------------------------------------------------------------- 

assign reset_reg = reset_b&reset_datapath_n;

//----------------------------------------------------------------------------------------
// ADDRESS ASSIGNMENT
//---------------------------------------------------------------------------------------- 

 always @(posedge clk) begin
  if(!(reset_reg)) begin
    addr_conv_weights <= 0;
  end
  else begin
    addr_conv_weights <= addr_conv_weights + incr_weight_addr;
  end
 end
 assign weights_sram_read_address= (en_weight_reg)?addr_conv_weights:addr_fc_weights;

//----------------------------------------------------------------------------------------
// WEIGHT REGISTER ASSIGNMENT
//---------------------------------------------------------------------------------------- 


always @(posedge clk) begin
  if(en_weight_reg) begin
    conv_weights[0] <= weights_sram_read_data[15:8];  
    conv_weights[1] <= weights_sram_read_data[7:0];

    conv_weights[2] <= conv_weights[0];
    conv_weights[4] <= conv_weights[2];
    conv_weights[6] <= conv_weights[4];
    conv_weights[8] <= conv_weights[6]; 

    conv_weights[3] <= conv_weights[1];
    conv_weights[5] <= conv_weights[3];
    conv_weights[7] <= conv_weights[5];
    conv_weights[9] <= conv_weights[7];
  end
end

//----------------------------------------------------------------------------------------
// CONVOLUTION UNIT DATAPATH
//---------------------------------------------------------------------------------------- 

//---------------------------------------------------------------------------
//Convolution Iteration Counter

always @(posedge clk) begin
  if(!(reset_reg)) begin
    iteration_cntr_val <= 0;
  end
  else begin
    iteration_cntr_val <= iteration_cntr_val + en_iteration_cntr;
  end
end

//----------------------------------------------------------------------------------------
// Convlution FSM Instantiation
//---------------------------------------------------------------------------------------- 


conv_fsm CONV_FSM(
  .dut_run(dut_run),
  .reset_b(reset_b),  
  .clk(clk),
  .incr_weight_addr(incr_weight_addr),
  .end_of_input_data(stop_conv), 
  .final_calc(is_last_iteration),
  .val_cntr_conv_itr(iteration_cntr_val),
  .en_weight_reg(en_weight_reg),
  .ACC_enable(ACC_Enable),
  .ACC_send(ACC_Send),
  .ACC_clear(ACC_Clear),
  .en_col_incr(en_col_incr),
  .en_addr_incr_mode2(en_addr_incr_mode2),
  .en_addr_incr_mode1(en_addr_incr_mode1),
  .en_cntr_conv_itr(en_iteration_cntr),     
  .read_N(read_N),
  .dut_busy(dut_busy),
  .val_incr_base_addr(val_incr_base_addr),
  .matrix_done_flag(matrix_done_flag),
  .reset_datapath_n(reset_datapath_n),
  .trigger_fc_fsm(trigger_fc_fsm)
);


//----------------------------------------------------------------------------------------
// Reading N
//---------------------------------------------------------------------------------------- 

always @(posedge clk) begin 
  if(!(reset_reg)) begin 
     N <= 0;
     base_ptr <= 0;
  end
  else if(read_N) begin 
     N <= input_sram_read_data[7:0];
     base_ptr <= input_sram_read_address + val_incr_base_addr;
  end
end

//----------------------------------------------------------------------------------------
// Generation of stop signal
//---------------------------------------------------------------------------------------- 

assign stop_conv = (input_sram_read_data == 16'hFFFF);

//----------------------------------------------------------------------------------------
// Generation of last signal
//---------------------------------------------------------------------------------------- 

assign is_last_iteration = ((row == (N-2))&(col == 0 ));

//----------------------------------------------------------------------------------------
// ROW AND COLUMN INCREMENT
//---------------------------------------------------------------------------------------- 

always @(posedge clk) begin 
  if(!(reset_reg)|(read_N)) begin 
     row <= 0;
     col <= 0;
  end
  else if(en_col_incr) begin 
     if(col == (N>>1)-2) begin 
      row <= row + `ROW_STRIDE;
      col <= 0;
     end
     else 
      col <= col + `COL_STRIDE;
  end
end

//----------------------------------------------------------------------------------------
// INPUT SRAM ADDRESS GENERATION
//---------------------------------------------------------------------------------------- 

//---------------------------------------------------------------------------
// Enable Output SRAM Write

assign input_sram_write_enable = 0;

always @(posedge clk) begin 
  if(!(reset_reg)) 
     input_sram_read_address <= 0;
  else if(en_addr_incr_mode2) begin 
     if(is_last_iteration)
      input_sram_read_address <= input_sram_read_address + 1;
     else
      input_sram_read_address <= col + row*(N>>1) + base_ptr;
  end
  else if(read_N|(en_addr_incr_mode1&(!en_iteration_cntr))) 
      input_sram_read_address <= input_sram_read_address + 1;
  else if(en_addr_incr_mode1)
     input_sram_read_address <= input_sram_read_address + ((!(iteration_cntr_val[0]))?((N>>1) -1):1);
end

//----------------------------------------------------------------------------------------
// Convolution Weight SRAMs
//---------------------------------------------------------------------------------------- 
//---------------------------------------------------------------------------
//Convolution Unit 0, Higher Weights
always @(*) begin
  if(iteration_cntr_val == 3'b000) 
    Weight_H[0] = conv_weights[`W00];
  else if(iteration_cntr_val == 3'b001) 
    Weight_H[0] = conv_weights[`W02];
  else if(iteration_cntr_val == 3'b010) 
    Weight_H[0] = conv_weights[`W10];
  else if(iteration_cntr_val == 3'b011) 
    Weight_H[0] = conv_weights[`W12];
  else if(iteration_cntr_val == 3'b100) 
    Weight_H[0] = conv_weights[`W20];
  else if(iteration_cntr_val == 3'b101) 
    Weight_H[0] = conv_weights[`W22];
  else
    Weight_H[0] = 0;
end

//---------------------------------------------------------------------------
//Convolution Unit 0, Lower Weights
always @(*) begin
  if(iteration_cntr_val == 3'b000) 
    Weight_L[0] = conv_weights[`W01];
  else if(iteration_cntr_val == 3'b010) 
    Weight_L[0] = conv_weights[`W11];
  else if(iteration_cntr_val == 3'b100) 
    Weight_L[0] = conv_weights[`W21];
  else 
    Weight_L[0] = 0;
end

//---------------------------------------------------------------------------
//Convolution Unit 1, Higher Weights
always @(*) begin
  if(iteration_cntr_val == 3'b001) 
    Weight_H[1] = conv_weights[`W01];
  else if(iteration_cntr_val == 3'b011) 
    Weight_H[1] = conv_weights[`W11];
  else if(iteration_cntr_val == 3'b101) 
    Weight_H[1] = conv_weights[`W21];
  else
    Weight_H[1] = 0;
end

//---------------------------------------------------------------------------
//Convolution Unit 1, Lower Weights
always @(*) begin
  if(iteration_cntr_val == 3'b000) 
    Weight_L[1] = conv_weights[`W00];
  else if(iteration_cntr_val == 3'b001) 
    Weight_L[1] = conv_weights[`W02];
  else if(iteration_cntr_val == 3'b010) 
    Weight_L[1] = conv_weights[`W10];
  else if(iteration_cntr_val == 3'b011) 
    Weight_L[1] = conv_weights[`W12];
  else if(iteration_cntr_val == 3'b100) 
    Weight_L[1] = conv_weights[`W20];
  else if(iteration_cntr_val == 3'b101) 
    Weight_L[1] = conv_weights[`W22];
  else
    Weight_L[1] = 0;
end

//---------------------------------------------------------------------------
//Convolution Unit 2, Higher Weights
always @(*) begin
  if(iteration_cntr_val == 3'b010) 
    Weight_H[2] = conv_weights[`W00];
  else if(iteration_cntr_val == 3'b011) 
    Weight_H[2] = conv_weights[`W02];
  else if(iteration_cntr_val == 3'b100) 
    Weight_H[2] = conv_weights[`W10];
  else if(iteration_cntr_val == 3'b101) 
    Weight_H[2] = conv_weights[`W12];
  else if(iteration_cntr_val == 3'b110) 
    Weight_H[2] = conv_weights[`W20];
  else if(iteration_cntr_val == 3'b111) 
    Weight_H[2] = conv_weights[`W22];
  else
    Weight_H[2] = 0;
end

//---------------------------------------------------------------------------
//Convolution Unit 2, Lower Weights
always @(*) begin
  if(iteration_cntr_val == 3'b010) 
    Weight_L[2] = conv_weights[`W01];
  else if(iteration_cntr_val == 3'b100) 
    Weight_L[2] = conv_weights[`W11];
  else if(iteration_cntr_val == 3'b110) 
    Weight_L[2] = conv_weights[`W21];
  else 
    Weight_L[2] = 0;
end

//---------------------------------------------------------------------------
//Convolution Unit 3, Higher Weights
always @(*) begin
  if(iteration_cntr_val == 3'b011) 
    Weight_H[3] = conv_weights[`W01];
  else if(iteration_cntr_val == 3'b101) 
    Weight_H[3] = conv_weights[`W11];
  else if(iteration_cntr_val == 3'b111) 
    Weight_H[3] = conv_weights[`W21];
  else
    Weight_H[3] = 0;
end

//---------------------------------------------------------------------------
//Convolution Unit 3, Lower Weights
always @(*) begin
  if(iteration_cntr_val == 3'b010) 
    Weight_L[3] = conv_weights[`W00];
  else if(iteration_cntr_val == 3'b011) 
    Weight_L[3] = conv_weights[`W02];
  else if(iteration_cntr_val == 3'b100) 
    Weight_L[3] = conv_weights[`W10];
  else if(iteration_cntr_val == 3'b101) 
    Weight_L[3] = conv_weights[`W12];
  else if(iteration_cntr_val == 3'b110) 
    Weight_L[3] = conv_weights[`W20];
  else if(iteration_cntr_val == 3'b111) 
    Weight_L[3] = conv_weights[`W22];
  else
    Weight_L[3] = 0;
end

//----------------------------------------------------------------------------------------
// Accumulators
//---------------------------------------------------------------------------------------- 
//---------------------------------------------------------------------------
//Convolution Unit 0

assign mult_H[0] = {{8{input_sram_read_data[15]}}, input_sram_read_data[15:8]} 
                    * {{8{Weight_H[0][7]}}, Weight_H[0]};
assign mult_L[0] = {{8{input_sram_read_data[7]}}, input_sram_read_data[7:0]} 
                    * {{8{Weight_L[0][7]}},  Weight_L[0]};

always @(posedge clk) begin 
  if(ACC_Clear[0])
    accumulators[0] <= 0;
  else if(ACC_Enable[0])
    accumulators[0] <= accumulators[0] + mult_H[0] 
                    + ((iteration_cntr_val[0] == 0)?mult_L[0]:0);
end

assign conv_ReLu[0] = (accumulators[0]> 20'sd0)?((accumulators[0] < 20'sd127)
                      ?accumulators[0][7:0]:20'sd127):20'sd0;
//---------------------------------------------------------------------------
//Convolution Unit 1

assign mult_H[1] = {{8{input_sram_read_data[15]}}, input_sram_read_data[15:8]}
                   * {{8{Weight_H[1][7]}}, Weight_H[1]};
assign mult_L[1] = {{8{input_sram_read_data[7]}}, input_sram_read_data[7:0]}
                   * {{8{Weight_L[1][7]}},  Weight_L[1]};

always @(posedge clk) begin 
  if(ACC_Clear[1])
    accumulators[1] <= 0;
  else if(ACC_Enable[1])
    accumulators[1] <= accumulators[1] 
                    + ((iteration_cntr_val[0] == 1)?mult_H[1]:0) + mult_L[1];
end

assign conv_ReLu[1] = (accumulators[1]> 20'sd0)?((accumulators[1] < 20'sd127)
                      ?accumulators[1][7:0]:20'sd127):20'sd0;
//---------------------------------------------------------------------------
//Convolution Unit 2

assign mult_H[2] = {{8{input_sram_read_data[15]}}, input_sram_read_data[15:8]}
                   * {{8{Weight_H[2][7]}}, Weight_H[2]};
assign mult_L[2] = {{8{input_sram_read_data[7]}}, input_sram_read_data[7:0]}
                   * {{8{Weight_L[2][7]}},  Weight_L[2]};

always @(posedge clk) begin 
  if(ACC_Clear[2])
    accumulators[2] <= 0;
  else if(ACC_Enable[2])
    accumulators[2] <= accumulators[2] + mult_H[2] 
                      + ((iteration_cntr_val[0] == 0)?mult_L[2]:0);
end

assign conv_ReLu[2] = (accumulators[2]> 20'sd0)?((accumulators[2] < 20'sd127)
                      ?accumulators[2][7:0]:20'sd127):20'sd0;

//---------------------------------------------------------------------------
//Convolution Unit 3

assign mult_H[3] = {{8{input_sram_read_data[15]}}, input_sram_read_data[15:8]}
                   * {{8{Weight_H[3][7]}}, Weight_H[3]};
assign mult_L[3] = {{8{input_sram_read_data[7]}}, input_sram_read_data[7:0]}
                   * {{8{Weight_L[3][7]}},  Weight_L[3]};

always @(posedge clk) begin 
  if(ACC_Clear[3])
    accumulators[3] <= 0;
  else if(ACC_Enable[3])
    accumulators[3] <= accumulators[3] 
                    + ((iteration_cntr_val[0] == 1)?mult_H[3]:0) + mult_L[3];
end

assign conv_ReLu[3] = (accumulators[3]> 20'sd0)?((accumulators[3] < 20'sd127)
                      ?accumulators[3][7:0]:20'sd127):20'sd0;

//----------------------------------------------------------------------------------------
// MAX POOLING UNIT
//---------------------------------------------------------------------------------------- 

//----------------------------------------------------------------------------------------
// MAX POOLING CONTROL SIGNALS
//---------------------------------------------------------------------------------------- 

//---------------------------------------------------------------------------
// For Input Flip flops
assign trigger_mp_H = |ACC_Send[1:0];  
assign trigger_mp_L = |ACC_Send[3:2];  

//---------------------------------------------------------------------------
// For Intermediate & Output Flip flops

always @(posedge clk) begin
  if(!(reset_reg)) begin
    trigger_mp_delayed_1 <= 0;
    trigger_mp_delayed_3 <= 0;
  end
  else begin
    trigger_mp_delayed_1 <= (trigger_mp_H|trigger_mp_L);
    trigger_mp_delayed_3 <= trigger_mp_delayed_1;
  end
end

//----------------------------------------------------------------------------------------
// MAX POOLING DONE FLAG SIGNALS
//---------------------------------------------------------------------------------------- 
 
always @(posedge clk) begin
  if(!(reset_reg)) begin
    matrix_done_flag_delayed <= 3'b0;
  end
  else begin
    matrix_done_flag_delayed <= {matrix_done_flag_delayed[2:1],matrix_done_flag};
  end
end

//----------------------------------------------------------------------------------------
// MAX POOLING INPUT FLIP FLOPS
//---------------------------------------------------------------------------------------- 

always @(posedge clk) begin 
  if(!(reset_reg)) begin
    maxPooling_input[0] <= 0;
    maxPooling_input[1] <= 0;
    maxPooling_input[2] <= 0;
    maxPooling_input[3] <= 0;
  end
  else if(trigger_mp_H) begin 
    maxPooling_input[0] <= conv_ReLu[0];
    maxPooling_input[1] <= conv_ReLu[1];
  end
  else if(trigger_mp_L) begin 
    maxPooling_input[2] <= conv_ReLu[2];
    maxPooling_input[3] <= conv_ReLu[3];
  end
end

//----------------------------------------------------------------------------------------
// MAX POOLING INTERMEDIATE (COMPARISON) FLIP FLOPS
//---------------------------------------------------------------------------------------- 
//---------------------------------------------------------------------------
// Comparison Unit H

assign maxPooling_compute_H = (maxPooling_input[1] > maxPooling_input[0])
                            ?maxPooling_input[1]:maxPooling_input[0];


//---------------------------------------------------------------------------
// Comparison Unit L

assign maxPooling_compute_L = (maxPooling_input[3] > maxPooling_input[2])
                            ?maxPooling_input[3]:maxPooling_input[2];


//----------------------------------------------------------------------------------------
// MAX POOLING OUTPUT REGISTER
//---------------------------------------------------------------------------------------- 
//---------------------------------------------------------------------------
// OUTPUT REGISTER 0

always @(posedge clk) begin
  if(!(reset_reg))
    maxPooling_output[0] <= 0;
  else if(trigger_mp_delayed_1 &(val_max_pooling_itr[1] == 0)) begin
    maxPooling_output[0] <= (maxPooling_compute_H > maxPooling_compute_L)?
                            maxPooling_compute_H:maxPooling_compute_L;
  end
end

//---------------------------------------------------------------------------
// OUTPUT REGISTER 1

always @(posedge clk) begin
  if(!(reset_reg))
    maxPooling_output[1] <= 0;
  else if(trigger_mp_delayed_1 &(val_max_pooling_itr[1] == 1)) begin
    maxPooling_output[1] <= (maxPooling_compute_H > maxPooling_compute_L)?
                            maxPooling_compute_H:maxPooling_compute_L;
  end
end

//---------------------------------------------------------------------------
//Max pooling Iteration Counter

always @(posedge clk) begin
  if(!(reset_reg&(!matrix_done_flag_delayed[2]))) begin
    val_max_pooling_itr <= 0;
  end
  else if(trigger_mp_delayed_3) begin
    val_max_pooling_itr <= val_max_pooling_itr + 1;
  end
end
  
//---------------------------------------------------------------------------
// Enable Output SRAM Write

assign output_sram_write_enable = (!trigger_fc_fsm)?1:0;

//---------------------------------------------------------------------------
// Output SRAM Data Assignment

assign output_sram_write_data[15:8] = maxPooling_output[0];
assign output_sram_write_data[7:0] = (matrix_done_flag_delayed[2])
                                      ?0:maxPooling_output[1];

//---------------------------------------------------------------------------
// Output SRAM Address Generation

always @(posedge clk) begin 
  if(!(reset_reg))
    output_sram_write_addresss <= 0;
  else if(((trigger_mp_delayed_3)&(val_max_pooling_itr == 2'b11))
          |(matrix_done_flag_delayed[2]))
    output_sram_write_addresss <= output_sram_write_addresss + 1;
end

endmodule

