
module conv_fsm (
//---------------------------------------------------------------------------
//Input signals
  input   wire        dut_run                    ,
  input   wire        reset_b                    ,  
  input   wire        clk                        ,
  input   wire        end_of_input_data          , //When N reads FFFF
  input   wire        final_calc                 , //Last item in NxN dataset
  input   wire [2:0]  val_cntr_conv_itr          , 
 
//---------------------------------------------------------------------------
//Output signals
  output reg          incr_weight_addr    ,
  output reg          en_weight_reg       ,
  output reg   [3:0]  ACC_enable          ,
  output reg   [3:0]  ACC_send            ,
  output reg   [3:0]  ACC_clear           ,
  output reg          en_col_incr         ,
  output reg          en_addr_incr_mode2  ,
  output reg          en_addr_incr_mode1  ,
  output reg          en_cntr_conv_itr    ,     
  output reg          read_N              ,
  output reg          dut_busy            ,
  output reg          val_incr_base_addr  ,
  output reg          matrix_done_flag    ,
  output reg          reset_datapath_n    ,
  output reg          trigger_fc_fsm
);
//----------------------------------------------------------------------------------------
// REGISTER DECLARATION
//---------------------------------------------------------------------------------------- 

  reg    [4:0]      curr_state;
  reg    [4:0]      next_state;
  reg    [3:0]      ACC_enable_ini;
  reg               en_weight_reg_;
//----------------------------------------------------------------------------------------
// PARAMETER DECLARATION
//---------------------------------------------------------------------------------------- 

  localparam [4:0]      S_IDLE = 0, 
                        S_READ_WEIGHTS_0 = 1,
                        S_READ_WEIGHTS_1 = 2,
                        S_READ_WEIGHTS_2 = 3,
                        S_READ_WEIGHTS_3 = 4,
                        S_READ_WEIGHTS_4 = 5,
                        S_READ_N = 6,
                        S_CONV_INIT = 7,
                        S_CONV_CALC_0 = 8,
                        S_CONV_CALC_1 = 9,
                        S_CONV_CALC_2 = 10,
                        S_CONV_CALC_3 = 11,
                        S_CONV_CALC_4 = 12,
                        S_CONV_CALC_5 = 13,
                        S_CONV_CALC_6 = 14,
                        S_CONV_CALC_7 = 15,
                        S_NEXT_DATASET = 16;
                        //S_STALL_FOR_FC;
                  
//----------------------------------------------------------------------------------------
// STATE UPDATION
//---------------------------------------------------------------------------------------- 

  always @(posedge clk) begin
    if(!reset_b) begin
      curr_state <= S_IDLE;
    end
    else begin
      curr_state <= next_state;
    end
  end


//----------------------------------------------------------------------------------------
// NEXT STATE AND OUTPUT LOGIC
//---------------------------------------------------------------------------------------- 
  always @(*) begin
    dut_busy = 1; 
    en_weight_reg_ = 0;
    trigger_fc_fsm = 0;
    case(curr_state) 
        //Default or Idle state
        S_IDLE: begin

          {ACC_clear, ACC_enable_ini, ACC_send} = 12'h0;
          {en_col_incr, en_addr_incr_mode1, en_addr_incr_mode2} = 3'b0;
          {incr_weight_addr, en_cntr_conv_itr} = 2'b0;
          {read_N, val_incr_base_addr, matrix_done_flag} = 3'b000;

          dut_busy = 0;
          if(dut_run) begin
            reset_datapath_n = 0;
            next_state = S_READ_WEIGHTS_0;
            en_weight_reg_ = 1;
          end
          else begin
            reset_datapath_n = 1;
            next_state = S_IDLE;
          end
        end
        S_READ_WEIGHTS_0: begin
          
          {ACC_enable_ini, ACC_send} = 8'h0;
          {en_col_incr, en_addr_incr_mode1, en_addr_incr_mode2} = 3'b0;
          {en_cntr_conv_itr} = 1'b0;
          {matrix_done_flag, reset_datapath_n} = 2'b01;
          read_N = 0;
          ACC_clear = 4'h0;
          val_incr_base_addr = 0;
          en_weight_reg_  = 1;
          incr_weight_addr = 1;
            next_state = S_READ_WEIGHTS_1;
        end
        S_READ_WEIGHTS_1: begin
          
          {ACC_enable_ini, ACC_send} = 8'h0;
          {en_col_incr, en_addr_incr_mode1, en_addr_incr_mode2} = 3'b0;
          {en_cntr_conv_itr} = 1'b0;
          {matrix_done_flag, reset_datapath_n} = 2'b01;
          read_N = 0;
          ACC_clear = 4'h0;
          val_incr_base_addr = 0;
          en_weight_reg_  = 1;
        
          incr_weight_addr = 1;
          next_state = S_READ_WEIGHTS_2;
        end
        S_READ_WEIGHTS_2: begin
          
          {ACC_enable_ini, ACC_send} = 8'h0;
          {en_col_incr, en_addr_incr_mode1, en_addr_incr_mode2} = 3'b0;
          {en_cntr_conv_itr} = 1'b0;
          {matrix_done_flag, reset_datapath_n} = 2'b01;
          read_N = 0;
          ACC_clear = 4'h0;
          val_incr_base_addr = 0;
          en_weight_reg_  = 1;
        
          incr_weight_addr = 1;
          next_state = S_READ_WEIGHTS_3;
        end
        S_READ_WEIGHTS_3: begin
          
          {ACC_enable_ini, ACC_send} = 8'h0;
          {en_col_incr, en_addr_incr_mode1, en_addr_incr_mode2} = 3'b0;
          {en_cntr_conv_itr} = 1'b0;
          {matrix_done_flag, reset_datapath_n} = 2'b01;
          read_N = 0;
          ACC_clear = 4'h0;
          val_incr_base_addr = 0;
          en_weight_reg_  = 1;
        
          incr_weight_addr = 1;
          next_state = S_READ_WEIGHTS_4;
        end
        S_READ_WEIGHTS_4: begin
          
          {ACC_enable_ini, ACC_send} = 8'h0;
          {en_col_incr, en_addr_incr_mode1, en_addr_incr_mode2} = 3'b0;
          {en_cntr_conv_itr} = 1'b0;
          {matrix_done_flag, reset_datapath_n} = 2'b01;
          read_N = 0;
          ACC_clear = 4'h0;
          val_incr_base_addr = 0;
          en_weight_reg_  = 1;
          incr_weight_addr = 1;
            //incr_weight_addr = 0;
            read_N = 1;
            ACC_clear = 4'hF;
            val_incr_base_addr = 1;
            next_state = S_READ_N;
        end
        S_READ_N: begin 
          {ACC_clear, ACC_send} = 8'h0;
          {en_col_incr, en_addr_incr_mode2} = 2'b0;
          {incr_weight_addr, en_cntr_conv_itr} = 2'b0;
          {read_N, val_incr_base_addr, matrix_done_flag,reset_datapath_n} = 4'b0001;
          
          if(end_of_input_data) begin 
            ACC_enable_ini = 4'h0;
            en_addr_incr_mode1 = 0;
            next_state = S_IDLE;
          end
          else begin 
            ACC_enable_ini =  4'b0011;
            en_addr_incr_mode1 = 1;
            read_N = 1;
            next_state = S_CONV_INIT;
          end
        end

        S_CONV_INIT: begin  
          {ACC_clear, ACC_enable_ini, ACC_send} = 12'h030;
          {en_col_incr, en_addr_incr_mode1, en_addr_incr_mode2} = 3'b010;
          {incr_weight_addr, en_cntr_conv_itr} = 2'b01;
          {read_N, val_incr_base_addr, matrix_done_flag,reset_datapath_n} = 4'b0001;
          next_state = S_CONV_CALC_1;
        end
        S_CONV_CALC_0: begin 
          {ACC_clear, ACC_enable_ini, ACC_send} = 12'hC3C;
          {en_col_incr, en_addr_incr_mode1, en_addr_incr_mode2} = 3'b010;
          {incr_weight_addr, en_cntr_conv_itr} = 2'b01;
          {read_N, val_incr_base_addr, matrix_done_flag,reset_datapath_n} = 4'b0001;
          next_state = S_CONV_CALC_1;
        end
        S_CONV_CALC_1: begin 
          {ACC_clear, ACC_enable_ini, ACC_send} = 12'h0F0;
          {en_col_incr, en_addr_incr_mode1, en_addr_incr_mode2} = 3'b110;
          {incr_weight_addr, en_cntr_conv_itr} = 2'b01;
          {read_N, val_incr_base_addr, matrix_done_flag,reset_datapath_n} = 4'b0001;
          next_state = S_CONV_CALC_2;
        end
        S_CONV_CALC_2: begin 
          {ACC_clear, ACC_send} = 8'h0;
          {en_col_incr, en_addr_incr_mode1, en_addr_incr_mode2} = 3'b010;
          {incr_weight_addr, en_cntr_conv_itr} = 2'b01;
          {read_N, val_incr_base_addr, matrix_done_flag,reset_datapath_n} = 4'b0001;
            ACC_enable_ini = 4'hF;
          next_state = S_CONV_CALC_3;
          end
        S_CONV_CALC_3: begin 
          {ACC_clear, ACC_send} = 8'h0;
          {en_col_incr, en_addr_incr_mode1, en_addr_incr_mode2} = 3'b010;
          {incr_weight_addr, en_cntr_conv_itr} = 2'b01;
          {read_N, val_incr_base_addr, matrix_done_flag,reset_datapath_n} = 4'b0001;
          ACC_enable_ini = 4'hF;
          next_state = S_CONV_CALC_4;
          end
        S_CONV_CALC_4: begin 
          {ACC_clear, ACC_send} = 8'h0;
          {en_col_incr, en_addr_incr_mode1, en_addr_incr_mode2} = 3'b010;
          {incr_weight_addr, en_cntr_conv_itr} = 2'b01;
          {read_N, val_incr_base_addr, matrix_done_flag,reset_datapath_n} = 4'b0001;
          ACC_enable_ini = 4'hF;
          next_state = S_CONV_CALC_5;
          end
        S_CONV_CALC_5: begin 
          {ACC_clear, ACC_send} = 8'h0;
          {en_col_incr, en_addr_incr_mode1, en_addr_incr_mode2} = 3'b010;
          {incr_weight_addr, en_cntr_conv_itr} = 2'b01;
          {read_N, val_incr_base_addr, matrix_done_flag,reset_datapath_n} = 4'b0001;
          ACC_enable_ini = 4'hC;
          next_state = S_CONV_CALC_6;
          end
        S_CONV_CALC_6: begin 
          {ACC_clear, ACC_enable_ini, ACC_send} = 12'h3C3;
          {en_col_incr, en_addr_incr_mode1, en_addr_incr_mode2} = 3'b001;
          {incr_weight_addr, en_cntr_conv_itr} = 2'b01;
          {read_N, val_incr_base_addr, matrix_done_flag,reset_datapath_n} = 4'b0001;
          next_state = S_CONV_CALC_7;
        end
        S_CONV_CALC_7: begin 
          {ACC_clear, ACC_send} = 8'h0;
          {en_col_incr, en_addr_incr_mode1, en_addr_incr_mode2} = 3'b010;
          {incr_weight_addr, en_cntr_conv_itr} = 2'b01;
          {read_N, val_incr_base_addr, matrix_done_flag,reset_datapath_n} = 4'b0001;
          if(final_calc) begin 
            ACC_enable_ini = 4'h0;
            next_state = S_NEXT_DATASET;
          end
          else begin
            ACC_enable_ini = 4'h3;
            next_state = S_CONV_CALC_0;
          end
        end
        S_NEXT_DATASET : begin
          {ACC_send} = 4'hC;
          {en_col_incr, en_addr_incr_mode2} = 2'b00;
          {incr_weight_addr, en_cntr_conv_itr} = 2'b00;
          {read_N, val_incr_base_addr, matrix_done_flag,reset_datapath_n} = 4'b1011;
          if(end_of_input_data) begin
            ACC_enable_ini = 4'h0;
            ACC_clear = 4'h0;
            en_addr_incr_mode1 = 0;
            next_state = S_IDLE;
          end
          else begin
            ACC_enable_ini = 4'h3;
            ACC_clear = 4'hC;
            en_addr_incr_mode1 = 1;
            next_state = S_CONV_INIT;
          end
        end
        
    endcase
  end

//----------------------------------------------------------------------------------------
// DELAY LOGIC FOR OUTPUT CONTROL SIGNALS
//---------------------------------------------------------------------------------------- 

  always @(posedge clk) begin
    if(!reset_b) begin
      ACC_enable <= 0;
      en_weight_reg <= 0;
    end
    else begin
      ACC_enable <= ACC_enable_ini;
      en_weight_reg <= en_weight_reg_;
    end
  end

endmodule

