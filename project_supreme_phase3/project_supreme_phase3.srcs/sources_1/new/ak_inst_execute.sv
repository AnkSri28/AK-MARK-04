`define add 1 //000001
`define mov 2 //000010
`define movi 33 //100001
`define sub 3 //000011
`define mul 4 //000100
`define div 5 //000101
`define jmp 6 //000110
`define bjnz 14 //001110
`define orl 19
`define andl 20
`define xrl 21
`define notl 22
`define cmp 23
`define ldr 24//011000
`define str 25//011001
`define shrt 26
`define shlt 27
`define immshrt 28
`define immshlt 29
`define inc 30
`define dec 31
`define addi 34
`define subi 35


module akie#(
    parameter INST_SIZE = 45,
    parameter REG_SIZE = 32
    )(
		input clk,
		input rst,
		input [INST_SIZE-1:0]inst,
		input valid_inst,
		output reg ready_inst,
		output reg inst_done,
		output reg [5:0]jmp_addr_pc,
		output reg jmp_addr_pc_valid);
////////////////////////////////////
reg [3:0] pipe_next;
reg [INST_SIZE-1:0] inst_reg;
reg [5:0] opcode;
reg [5:0] operation;
reg [REG_SIZE-1:0] opregs1,opregs2,opregout,opregout2;
////////////registers///////////////
reg [REG_SIZE-1:0]rg0;//nzcv flags
reg [REG_SIZE-1:0]rg1;
reg [REG_SIZE-1:0]rg2;
reg [REG_SIZE-1:0]rg3;
reg [REG_SIZE-1:0]rg4;
reg [REG_SIZE-1:0]rg5;
reg [REG_SIZE-1:0]rg6;
reg [REG_SIZE-1:0]rg7;
reg [REG_SIZE-1:0]rg8;
reg [REG_SIZE-1:0]rg9;
reg [REG_SIZE-1:0]rg10;
reg [REG_SIZE-1:0]rg11;
reg [REG_SIZE-1:0]rg12;
reg [REG_SIZE-1:0]rg13;
reg [REG_SIZE-1:0]rg14;
reg [REG_SIZE-1:0]rg15;
reg [REG_SIZE-1:0]rg16;
reg [REG_SIZE-1:0]rg17;
reg [REG_SIZE-1:0]rg18;
reg [REG_SIZE-1:0]rg19;
reg [REG_SIZE-1:0]rg20;
reg [REG_SIZE-1:0]rg21;
reg [REG_SIZE-1:0]rg22;
reg [REG_SIZE-1:0]rg23;
reg [REG_SIZE-1:0]rg24;
reg [REG_SIZE-1:0]rg25;
reg [REG_SIZE-1:0]rg26;
reg [REG_SIZE-1:0]rg27;
reg [REG_SIZE-1:0]rg28;
reg [REG_SIZE-1:0]rg29;
reg [REG_SIZE-1:0]rg30;
reg [REG_SIZE-1:0]rg31;
////////////////////////////////////
reg [REG_SIZE-1:0]imm_val;
reg regload;
////////////////////////////////////
////////divider regs////////////////
reg [REG_SIZE-1:0]dividend;//a
reg dividend_valid;
wire dividend_ready;
reg [REG_SIZE-1:0]divisor;//b
reg divisor_valid;
wire divisor_ready;
wire [REG_SIZE*2-1:0]div_out;
wire div_out_valid;
reg div_out_ready;
reg div_zero;
reg div_en;
reg [1:0]div_next;
////////////////////////////////////
/////////branch pred////////////////
reg branch_pred_en;
////////////////////////////////////
///////AXI lite mem access//////////
reg [REG_SIZE-1:0]m_axi_araddr;
reg m_axi_arready;
reg m_axi_arvalid;
reg [REG_SIZE-1:0]m_axi_awaddr;
reg m_axi_awready;
reg m_axi_awvalid;
reg m_axi_bready;
reg m_axi_bvalid;
reg [1:0]m_axi_bresp;
reg [REG_SIZE-1:0]m_axi_rdata;
reg m_axi_rready;
reg [1:0]m_axi_rresp;
reg m_axi_rvalid;
reg [REG_SIZE-1:0]m_axi_wdata;
reg m_axi_wready;
reg [3:0]m_axi_wstrb;
reg m_axi_wvalid;
////////////////////////////////////
///////////ldr/str//////////////////
reg [1:0]ldr_next;
reg [1:0]str_next;
////////////////////////////////////

localparam FETCH = 4'd0;
localparam DECODE1 = 4'd1;
localparam DECODE_EXTRA = 4'd2;
localparam DECODE2 = 4'd3;
localparam DECODE3 = 4'd4;
localparam EXECUTE = 4'd5;
localparam MEM_WRITE_MISC = 4'd6;
localparam MEM_WRITE = 4'd9;
localparam DONE = 4'd10;
/////////////////////////////////////
/////////////DIV PARAMETERS//////////
localparam INP_READ = 2'd0;
localparam CHECK_OUT = 2'd1;
/////////////////////////////////////
///////////ldr/str///////////////////
localparam LDR_ADDR = 2'd0;
localparam LDR_VAL = 2'd1;
localparam STR_ADDR = 2'd0;
localparam STR_VAL = 2'd1;
localparam STR_RESP = 2'd2;
/////////////////////////////////////

always @(posedge clk) begin
	if(rst)begin
		ready_inst <= 0;
		operation <= 'd0;
		rg0 <= 'd0;
		rg1 <= 'd0;
		rg2 <= 'd0;
		rg3 <= 'd0;
		rg4 <= 'd0;
		rg5 <= 'd0;
		rg6 <= 'd0;
		rg7 <= 'd0;
		rg8 <= 'd0;
		rg9 <= 'd0;
		rg10 <= 'd0;
		rg11 <= 'd0;
		rg12 <= 'd0;
		rg13 <= 'd0;
		rg14 <= 'd0;
		rg15 <= 'd0;
	    rg16 <= 'd0;
        rg17 <= 'd0;
        rg18 <= 'd0;
        rg19 <= 'd0;
        rg20 <= 'd0;
        rg21 <= 'd0;
        rg22 <= 'd0;
        rg23 <= 'd0;
        rg24 <= 'd0;
        rg25 <= 'd0;
        rg26 <= 'd0;
        rg27 <= 'd0;
        rg28 <= 'd0;
        rg29 <= 'd0;
        rg30 <= 'd0;
        rg31 <= 'd0;
		opregs1 <= 'd0;
		opregs2 <= 'd0;
		opregout <= 'd0;
		opcode <= 'd0;
		imm_val <= 'd0;
		regload <= 'd0;
		dividend <= 'd0;
		dividend_valid <= 'd0;
		divisor <= 'd0;
		divisor_valid <= 'd0;
		div_en <=0;
		div_out_ready <= 0;
		////////////////////
		m_axi_arvalid <= 0;
		m_axi_rready <= 0;
		m_axi_awvalid <= 0;
		m_axi_wvalid <= 0;
		m_axi_bready <= 0;
		m_axi_araddr <= 'd0;
		m_axi_awaddr <= 'd0;
		m_axi_wdata <= 'd0;
		m_axi_wstrb <= 'd0;
		////////////////////
	end
	else begin
	  case(pipe_next)
		FETCH:begin
		    inst_done <= 0;
		    ready_inst <= 1;
            if(valid_inst && ready_inst)begin
                inst_reg <= inst;
                opcode = inst[44:39];
                ready_inst <= 0;
                pipe_next <= DECODE1;
            end
            else begin
                pipe_next <= FETCH;
            end
           end
         DECODE1:begin
            case(opcode)
               `add:begin 
                  operation <= 6'd1;
                  pipe_next <= DECODE2;    
               end
               `mov:begin 
                   operation <= 6'd2;
                   pipe_next <= DECODE2;    
               end
               `sub:begin 
                   operation <= 6'd3;
                   pipe_next <= DECODE2;    
               end
               `mul:begin
                    operation <= 6'd4;
                    pipe_next <= DECODE2;
               end
               `div:begin
                    operation <= 6'd5;
                    div_en <= 1;
                    pipe_next <= DECODE2;
               end
              `jmp:begin
                    operation <= 6'd6;
                    pipe_next <= EXECUTE;
               end
               `bjnz:begin
                     operation <= 6'd14;
                     branch_pred_en <= 1;
                     pipe_next <= DECODE_EXTRA;
                end
                `orl:begin
                      operation <= 6'd19;
                      pipe_next <= DECODE2;
                end
                `andl:begin
                      operation <= 6'd20;
                      pipe_next <= DECODE2;
                end
                `xrl:begin
                      operation <= 6'd21;
                      pipe_next <= DECODE2;
                end
                `notl:begin
                      operation <= 6'd22;
                      pipe_next <= DECODE_EXTRA;
                end
                `cmp:begin
                      operation <= 6'd23;
                      pipe_next <= DECODE2;
                end
                `ldr:begin
                      operation <= 6'd24;
                      pipe_next <= EXECUTE;
                end
                `str:begin
                      operation <= 6'd25;
                      pipe_next <= DECODE_EXTRA;
                end
                `shrt:begin
                      operation <= 6'd26;
                      pipe_next <= DECODE2;
                     // imm_val = inst[31:0];
                end
                `shlt:begin
                      operation <= 6'd27;
                      pipe_next <= DECODE2;
                     // imm_val = inst[31:0];
                end
                `immshrt:begin
                      operation <= 6'd28;
                      pipe_next <= DECODE2;
                      imm_val = inst[31:0];
                end
                `immshlt:begin
                      operation <= 6'd29;
                      pipe_next <= DECODE2;
                      imm_val = inst[31:0];
                end
                `inc:begin
                      operation <= 6'd30;
                      pipe_next <= DECODE_EXTRA;
                end
                `dec:begin
                      operation <= 6'd31;
                      pipe_next <= DECODE_EXTRA;
                end
               `movi:begin
                   operation <= 6'd33;
                   imm_val = inst[31:0];
                   pipe_next <= EXECUTE;    
               end
               `addi:begin
                   operation <= 6'd34;
                   imm_val = inst[31:0];
                   pipe_next <= DECODE_EXTRA;    
               end
               `subi:begin
                   operation <= 6'd35;
                   imm_val = inst[31:0];
                   pipe_next <= DECODE_EXTRA;    
               end
               default:  
                  pipe_next <= DONE;       
              endcase 
           end
        DECODE_EXTRA:begin
               ready_inst <= 0;
               case(inst[38:34]) //output reg
                 5'b00000:begin opregout <= rg0;
                          pipe_next <= EXECUTE;
                          end
                 5'b00001:begin opregout <= rg1;
                          pipe_next <= EXECUTE;
                          end
                 5'b00010:begin opregout <= rg2;
                          pipe_next <= EXECUTE;
                          end
                 5'b00011:begin opregout <= rg3;
                          pipe_next <= EXECUTE;
                          end
                 5'b00100:begin opregout <= rg4;
                          pipe_next <= EXECUTE;
                          end
                 5'b00101:begin opregout <= rg5;
                          pipe_next <= EXECUTE;
                          end      
                 5'b00110:begin opregout <= rg6;
                          pipe_next <= EXECUTE;
                          end
                 5'b00111:begin opregout <= rg7;
                          pipe_next <= EXECUTE;
                          end
                 5'b01000:begin opregout <= rg8;
                          pipe_next <= EXECUTE;
                          end
                 5'b01001:begin opregout <= rg9;
                          pipe_next <= EXECUTE;
                          end
                 5'b01010:begin opregout <= rg10;
                          pipe_next <= EXECUTE;
                          end
                 5'b01011:begin opregout <= rg11;
                          pipe_next <= EXECUTE;
                          end
                 5'b01100:begin opregout <= rg12;
                          pipe_next <= EXECUTE;
                          end
                 5'b01101:begin opregout <= rg13;
                          pipe_next <= EXECUTE;
                          end
                 5'b01110:begin opregout <= rg14;
                          pipe_next <= EXECUTE;
                          end
                 5'b01111:begin opregout <= rg15;
                          pipe_next <= EXECUTE;
                          end         
                 5'b10000:begin opregout <= rg16;
                          pipe_next <= EXECUTE;
                          end
                 5'b10001:begin opregout <= rg17;
                          pipe_next <= EXECUTE;
                          end
                 5'b10010:begin opregout <= rg18;
                          pipe_next <= EXECUTE;
                          end
                 5'b10011:begin opregout <= rg19;
                          pipe_next <= EXECUTE;
                          end
                 5'b10100:begin opregout <= rg20;
                          pipe_next <= EXECUTE;
                          end
                 5'b10101:begin opregout <= rg21;
                          pipe_next <= EXECUTE;
                          end      
                 5'b10110:begin opregout <= rg22;
                          pipe_next <= EXECUTE;
                          end
                 5'b10111:begin opregout <= rg23;
                          pipe_next <= EXECUTE;
                          end
                 5'b11000:begin opregout <= rg24;
                          pipe_next <= EXECUTE;
                          end
                 5'b11001:begin opregout <= rg25;
                          pipe_next <= EXECUTE;
                          end
                 5'b11010:begin opregout <= rg26;
                          pipe_next <= EXECUTE;
                          end
                 5'b11011:begin opregout <= rg27;
                          pipe_next <= EXECUTE;
                          end
                 5'b11100:begin opregout <= rg28;
                          pipe_next <= EXECUTE;
                          end
                 5'b11101:begin opregout <= rg29;
                          pipe_next <= EXECUTE;
                          end
                 5'b11110:begin opregout <= rg30;
                          pipe_next <= EXECUTE;
                          end
                 5'b11111:begin opregout <= rg31;
                          pipe_next <= EXECUTE;
                          end 
                endcase
             end        
        DECODE2:begin
            ready_inst <= 0;
            case(inst[4:0]) //source reg 1
              5'b00000:begin opregs1 <= rg0;
                       pipe_next <= DECODE3;
                       end
              5'b00001:begin opregs1 <= rg1;
                       pipe_next <= DECODE3;
                       end
              5'b00010:begin opregs1 <= rg2;
                       pipe_next <= DECODE3;
                       end
              5'b00011:begin opregs1 <= rg3;
                       pipe_next <= DECODE3;
                       end
              5'b00100:begin opregs1 <= rg4;
                       pipe_next <= DECODE3;
                       end
              5'b00101:begin opregs1 <= rg5;
                       pipe_next <= DECODE3;
                       end      
              5'b00110:begin opregs1 <= rg6;
                       pipe_next <= DECODE3;
                       end
              5'b00111:begin opregs1 <= rg7;
                       pipe_next <= DECODE3;
                       end
              5'b01000:begin opregs1 <= rg8;
                       pipe_next <= DECODE3;
                       end
              5'b01001:begin opregs1 <= rg9;
                       pipe_next <= DECODE3;
                       end
              5'b01010:begin opregs1 <= rg10;
                       pipe_next <= DECODE3;
                       end
              5'b01011:begin opregs1 <= rg11;
                       pipe_next <= DECODE3;
                       end
              5'b01100:begin opregs1 <= rg12;
                       pipe_next <= DECODE3;
                       end
              5'b01101:begin opregs1 <= rg13;
                       pipe_next <= DECODE3;
                       end
              5'b01110:begin opregs1 <= rg14;
                       pipe_next <= DECODE3;
                       end
              5'b01111:begin opregs1 <= rg15;
                       pipe_next <= DECODE3;
                       end         
              5'b10000:begin opregs1 <= rg16;
                       pipe_next <= DECODE3;
                       end
              5'b10001:begin opregs1 <= rg17;
                       pipe_next <= DECODE3;
                       end
              5'b10010:begin opregs1 <= rg18;
                       pipe_next <= DECODE3;
                       end
              5'b10011:begin opregs1 <= rg19;
                       pipe_next <= DECODE3;
                       end
              5'b10100:begin opregs1 <= rg20;
                       pipe_next <= DECODE3;
                       end
              5'b10101:begin opregs1 <= rg21;
                       pipe_next <= DECODE3;
                       end      
              5'b10110:begin opregs1 <= rg22;
                       pipe_next <= DECODE3;
                       end
              5'b10111:begin opregs1 <= rg23;
                       pipe_next <= DECODE3;
                       end
              5'b11000:begin opregs1 <= rg24;
                       pipe_next <= DECODE3;
                       end
              5'b11001:begin opregs1 <= rg25;
                       pipe_next <= DECODE3;
                       end
              5'b11010:begin opregs1 <= rg26;
                       pipe_next <= DECODE3;
                       end
              5'b11011:begin opregs1 <= rg27;
                       pipe_next <= DECODE3;
                       end
              5'b11100:begin opregs1 <= rg28;
                       pipe_next <= DECODE3;
                       end
              5'b11101:begin opregs1 <= rg29;
                       pipe_next <= DECODE3;
                       end
              5'b11110:begin opregs1 <= rg30;
                       pipe_next <= DECODE3;
                       end
              5'b11111:begin opregs1 <= rg31;
                       pipe_next <= DECODE3;
                       end   
            endcase
          end
         DECODE3:begin
           case(inst[9:5]) //source reg 2
             5'b00000:begin opregs2 <= rg0;
                      pipe_next <= EXECUTE;
                      end
             5'b00001:begin opregs2 <= rg1;
                      pipe_next <= EXECUTE;
                      end
             5'b00010:begin opregs2 <= rg2;
                      pipe_next <= EXECUTE;
                      end
             5'b00011:begin opregs2 <= rg3;
                      pipe_next <= EXECUTE;
                      end
             5'b00100:begin opregs2 <= rg4;
                      pipe_next <= EXECUTE;
                      end
             5'b00101:begin opregs2 <= rg5;
                      pipe_next <= EXECUTE;
                      end      
             5'b00110:begin opregs2 <= rg6;
                      pipe_next <= EXECUTE;
                      end
             5'b00111:begin opregs2 <= rg7;
                      pipe_next <= EXECUTE;
                      end
             5'b01000:begin opregs2 <= rg8;
                      pipe_next <= EXECUTE;
                      end
             5'b01001:begin opregs2 <= rg9;
                      pipe_next <= EXECUTE;
                      end
             5'b01010:begin opregs2 <= rg10;
                      pipe_next <= EXECUTE;
                      end
             5'b01011:begin opregs2 <= rg11;
                      pipe_next <= EXECUTE;
                      end
             5'b01100:begin opregs2 <= rg12;
                      pipe_next <= EXECUTE;
                      end
             5'b01101:begin opregs2 <= rg13;
                      pipe_next <= EXECUTE;
                      end
             5'b01110:begin opregs2 <= rg14;
                      pipe_next <= EXECUTE;
                      end
             5'b01111:begin opregs2 <= rg15;
                      pipe_next <= EXECUTE;
                      end         
             5'b10000:begin opregs2 <= rg16;
                      pipe_next <= EXECUTE;
                      end
             5'b10001:begin opregs2 <= rg17;
                      pipe_next <= EXECUTE;
                      end
             5'b10010:begin opregs2 <= rg18;
                      pipe_next <= EXECUTE;
                      end
             5'b10011:begin opregs2 <= rg19;
                      pipe_next <= EXECUTE;
                      end
             5'b10100:begin opregs2 <= rg20;
                      pipe_next <= EXECUTE;
                      end
             5'b10101:begin opregs2 <= rg21;
                      pipe_next <= EXECUTE;
                      end      
             5'b10110:begin opregs2 <= rg22;
                      pipe_next <= EXECUTE;
                      end
             5'b10111:begin opregs2 <= rg23;
                      pipe_next <= EXECUTE;
                      end
             5'b11000:begin opregs2 <= rg24;
                      pipe_next <= EXECUTE;
                      end
             5'b11001:begin opregs2 <= rg25;
                      pipe_next <= EXECUTE;
                      end
             5'b11010:begin opregs2 <= rg26;
                      pipe_next <= EXECUTE;
                      end
             5'b11011:begin opregs2 <= rg27;
                      pipe_next <= EXECUTE;
                      end
             5'b11100:begin opregs2 <= rg28;
                      pipe_next <= EXECUTE;
                      end
             5'b11101:begin opregs2 <= rg29;
                      pipe_next <= EXECUTE;
                      end
             5'b11110:begin opregs2 <= rg30;
                      pipe_next <= EXECUTE;
                      end
             5'b11111:begin opregs2 <= rg31;
                      pipe_next <= EXECUTE;
                      end 
          endcase
          end
    EXECUTE:begin
        case(operation)
         6'd1:begin //add
            {rg0[29],opregout} <= opregs1 + opregs2;
            pipe_next <= MEM_WRITE;
         end
         6'd2:begin //mov
            opregs2 <= opregs1;
            pipe_next <= DONE;
                  end
         6'd3:begin //sub
             {rg0[29],opregout} <= opregs1 - opregs2;
             pipe_next <= MEM_WRITE;
                  end
          6'd4:begin //mul
             {opregout,opregout2} <= opregs1 * opregs2;
             pipe_next <= MEM_WRITE_MISC;
                  end
          6'd5:begin
          case(div_next)
          INP_READ:begin
            dividend <= opregs1;
            divisor_valid <= 1;
            dividend_valid <= 1;
            divisor <= opregs2;
            if(dividend_valid && dividend_ready && divisor_valid && divisor_ready)begin
                div_next <= CHECK_OUT;
            end
            else begin
                div_next <= INP_READ;
            end
          end
          CHECK_OUT:begin
              divisor_valid <= 0;
              dividend_valid <= 0;   
              div_out_ready <= 1; 
              if(div_out_valid && div_out_ready)begin
                {opregout,opregout2} <= div_out; 
                div_next <= INP_READ;           
                pipe_next <= MEM_WRITE_MISC;
              end
              else begin
                div_next <= CHECK_OUT;   
              end
          end
          default:begin
            div_next <= INP_READ;     
          end
          endcase
             end
          6'd6:begin
            jmp_addr_pc <= inst[5:0];
            jmp_addr_pc_valid <= 1;
            pipe_next <= DONE;
          end
          6'd14:begin
            if(~rg0[30])begin
               jmp_addr_pc <= inst[5:0];
               jmp_addr_pc_valid <= 1;
               pipe_next <= DONE;
            end
            else begin
               pipe_next <= DONE;
            end
          end
           6'd19:begin //or
               opregout <= opregs1 | opregs2;
               pipe_next <= MEM_WRITE;
            end
           6'd20:begin //and
                opregout <= opregs1 & opregs2;
                pipe_next <= MEM_WRITE;
            end
           6'd21:begin //xor
                 opregout <= opregs1 ^ opregs2;
                 pipe_next <= MEM_WRITE;
            end
           6'd22:begin //not
                 opregout <= ~opregout;
                 pipe_next <= DONE;
            end
            6'd23:begin //cmp
                  if(opregs1 < opregs2)begin
                    rg0[31] <= 1;
                    pipe_next <= DONE;
                  end                
                  else if(opregs1 == opregs2)begin
                     rg0[30] <= 1;
                     pipe_next <= DONE;
                  end
             end
            6'd24:begin //ldr
               case(ldr_next)
                LDR_ADDR:begin
                    m_axi_araddr <= inst[34:3];
                    m_axi_arvalid <= 1;
                    m_axi_rready <= 1;
                    ldr_next <= LDR_VAL;
                end
                LDR_VAL:begin
                    m_axi_arvalid <= 0;
                    if(m_axi_rvalid && m_axi_rready)begin
                       m_axi_rready <= 0;
                       opregout <= m_axi_rdata;
                       ldr_next <= LDR_ADDR;
                       pipe_next <= MEM_WRITE;
                    end            
                    else begin
                       ldr_next <= LDR_VAL;
                    end 
                end
                default:begin
                    ldr_next <= LDR_ADDR;
                end
               endcase
          end
            6'd25:begin //str              
           case(str_next)
             STR_ADDR:begin
                 m_axi_awaddr <= inst[34:3];
                 m_axi_awvalid <= 1;
                 m_axi_wdata <= opregout;
                 m_axi_wstrb <= 4'd15;
                 m_axi_wvalid <= 1;
                 str_next <= STR_VAL;
             end
             STR_VAL:begin
                 m_axi_arvalid <= 0;
                 if(m_axi_wvalid && m_axi_wready)begin
                    m_axi_wvalid <= 0;
                    m_axi_bready <= 1;
                    if(m_axi_bresp <= 2'b00)begin
                        str_next <= STR_ADDR;
                        pipe_next <= MEM_WRITE;
                    end
                 end            
                 else begin
                    str_next <= STR_VAL;
                 end 
             end
             default:begin
                 str_next <= STR_ADDR;
             end
            endcase
       end
       6'd26:begin//right shift
          opregs1 <= opregs1 >> opregs2;
          pipe_next <= DONE;
       end
       6'd27:begin//left shift
          opregs1 <= opregs1 << opregs2;
          pipe_next <= DONE;
       end
       6'd28:begin//imm rt shift
          opregs1 <= opregs1 >> imm_val;
          pipe_next <= DONE;
       end
       6'd29:begin//imm left shift
          opregs1 <= opregs1 << imm_val;;
          pipe_next <= DONE;
       end
       6'd30:begin //inc
             opregout <= opregout + 'd1;
             pipe_next <= DONE;
        end
       6'd31:begin //dec
              opregout <= opregout + 'd1;
              pipe_next <= DONE;
         end
          6'd33:begin
             opregout <= imm_val;
             pipe_next <= MEM_WRITE;
          end
          6'd34:begin
             opregout <= opregout + imm_val;
             pipe_next <= MEM_WRITE;
          end
          6'd34:begin
             opregout <= opregout - imm_val;
             pipe_next <= MEM_WRITE;
          end
        endcase
    end
    MEM_WRITE_MISC:begin
    case(inst[33:29]) //output reg2
      5'b00000:begin rg0 <= opregout2;
               pipe_next <= MEM_WRITE;
               end
      5'b00001: begin rg1 <= opregout2;
               pipe_next <= MEM_WRITE;
               end
      5'b00010: begin rg2 <= opregout2;
               pipe_next <= MEM_WRITE;
               end
      5'b00011: begin rg3 <= opregout2;
               pipe_next <= MEM_WRITE;
               end
      5'b00100: begin rg4 <= opregout2;
               pipe_next <= MEM_WRITE;
               end
      5'b00101: begin rg5 <= opregout2;
               pipe_next <= MEM_WRITE;
               end      
      5'b00110: begin rg6 <= opregout2;
               pipe_next <= MEM_WRITE;
               end
      5'b00111: begin rg7 <= opregout2;
               pipe_next <= MEM_WRITE;
               end
      5'b01000: begin rg8 <= opregout2;
               pipe_next <= MEM_WRITE;
               end
      5'b01001: begin rg9 <= opregout2;
               pipe_next <= MEM_WRITE;
               end
      5'b01010: begin rg10 <= opregout2;
               pipe_next <= MEM_WRITE;
               end
      5'b01011: begin rg11 <= opregout2;
               pipe_next <= MEM_WRITE;
               end
      5'b01100: begin rg12 <= opregout2;
               pipe_next <= MEM_WRITE;
               end
      5'b01101: begin rg13 <= opregout2;
               pipe_next <= MEM_WRITE;
               end
      5'b01110: begin rg14 <= opregout2;
               pipe_next <= MEM_WRITE;
               end
      5'b01111: begin rg15 <= opregout2;
               pipe_next <= MEM_WRITE;
               end
      5'b10000: begin rg16 <= opregout2;
               pipe_next <= MEM_WRITE;
               end
      5'b10001: begin rg17 <= opregout2;
               pipe_next <= MEM_WRITE;
               end
      5'b10010: begin rg18 <= opregout2;
               pipe_next <= MEM_WRITE;
               end
      5'b10011: begin rg19 <= opregout2;
               pipe_next <= MEM_WRITE;
               end
      5'b10100: begin rg20 <= opregout2;
               pipe_next <= MEM_WRITE;
               end
      5'b10101: begin rg21 <= opregout2;
               pipe_next <= MEM_WRITE;
               end      
      5'b10110: begin rg22 <= opregout2;
               pipe_next <= MEM_WRITE;
               end
      5'b10111: begin rg23 <= opregout2;
               pipe_next <= MEM_WRITE;
               end
      5'b11000: begin rg24 <= opregout2;
               pipe_next <= MEM_WRITE;
               end
      5'b11001: begin rg25 <= opregout2;
               pipe_next <= MEM_WRITE;
               end
      5'b11010: begin rg26 <= opregout2;
               pipe_next <= MEM_WRITE;
               end
      5'b11011: begin rg27 <= opregout2;
               pipe_next <= MEM_WRITE;
               end
      5'b11100: begin rg28 <= opregout2;
               pipe_next <= MEM_WRITE;
               end
      5'b11101: begin rg29 <= opregout2;
               pipe_next <= MEM_WRITE;
               end
      5'b11110: begin rg30 <= opregout2;
               pipe_next <= MEM_WRITE;
               end
      5'b11111: begin rg31 <= opregout2;
               pipe_next <= MEM_WRITE;
               end          
     endcase
    end
    MEM_WRITE:begin
    case(inst[38:34]) //output reg
    5'b00000:begin rg0 <= opregout;
             pipe_next <= DONE;
             end
    5'b00001: begin rg1 <= opregout;
             pipe_next <= DONE;
             end
    5'b00010: begin rg2 <= opregout;
             pipe_next <= DONE;
             end
    5'b00011: begin rg3 <= opregout;
             pipe_next <= DONE;
             end
    5'b00100: begin rg4 <= opregout;
             pipe_next <= DONE;
             end
    5'b00101: begin rg5 <= opregout;
             pipe_next <= DONE;
             end      
    5'b00110: begin rg6 <= opregout;
             pipe_next <= DONE;
             end
    5'b00111: begin rg7 <= opregout;
             pipe_next <= DONE;
             end
    5'b01000: begin rg8 <= opregout;
             pipe_next <= DONE;
             end
    5'b01001: begin rg9 <= opregout;
             pipe_next <= DONE;
             end
    5'b01010: begin rg10 <= opregout;
             pipe_next <= DONE;
             end
    5'b01011: begin rg11 <= opregout;
             pipe_next <= DONE;
             end
    5'b01100: begin rg12 <= opregout;
             pipe_next <= DONE;
             end
    5'b01101: begin rg13 <= opregout;
             pipe_next <= DONE;
             end
    5'b01110: begin rg14 <= opregout;
             pipe_next <= DONE;
             end
    5'b01111: begin rg15 <= opregout;
             pipe_next <= DONE;
             end
    5'b10000: begin rg16 <= opregout;
             pipe_next <= DONE;
             end
    5'b10001: begin rg17 <= opregout;
             pipe_next <= DONE;
             end
    5'b10010: begin rg18 <= opregout;
             pipe_next <= DONE;
             end
    5'b10011: begin rg19 <= opregout;
             pipe_next <= DONE;
             end
    5'b10100: begin rg20 <= opregout;
             pipe_next <= DONE;
             end
    5'b10101: begin rg21 <= opregout;
             pipe_next <= DONE;
             end      
    5'b10110: begin rg22 <= opregout;
             pipe_next <= DONE;
             end
    5'b10111: begin rg23 <= opregout;
             pipe_next <= DONE;
             end
    5'b11000: begin rg24 <= opregout;
             pipe_next <= DONE;
             end
    5'b11001: begin rg25 <= opregout;
             pipe_next <= DONE;
             end
    5'b11010: begin rg26 <= opregout;
             pipe_next <= DONE;
             end
    5'b11011: begin rg27 <= opregout;
             pipe_next <= DONE;
             end
    5'b11100: begin rg28 <= opregout;
             pipe_next <= DONE;
             end
    5'b11101: begin rg29 <= opregout;
             pipe_next <= DONE;
             end
    5'b11110: begin rg30 <= opregout;
             pipe_next <= DONE;
             end
    5'b11111: begin rg31 <= opregout;
             pipe_next <= DONE;
             end  
     endcase
    end
    DONE:begin
        inst_done <= 1;
        jmp_addr_pc_valid <= 0;
        div_en <= 0;
        pipe_next <= FETCH;
    end
	default:begin
		pipe_next <= FETCH;
	end
   endcase
	end
end
///////////////internal module declaration/////////////////////////////////
div_gen_0 div1(
           .aclk(clk),
           .aresetn(~rst),
           //.aclken(div_en),
           .s_axis_dividend_tdata(dividend),
           .s_axis_dividend_tvalid(dividend_valid),
           .s_axis_dividend_tready(dividend_ready),
           .s_axis_divisor_tdata(divisor),
           .s_axis_divisor_tvalid(divisor_valid),
           .s_axis_divisor_tready(divisor_ready),
           .m_axis_dout_tdata(div_out),
          // .m_axis_dout_tuser(div_zero),
           .m_axis_dout_tvalid(div_out_valid),
           .m_axis_dout_tready(div_out_ready)
                );
///////////////////////////////////////////////////////////////////////////
//////////////RAM//////////////////////////s////////////////////////////////
blk_mem_gen_1 mem2(.s_aclk(clk), 
                 .s_aresetn(~rst),
                 .s_axi_araddr(m_axi_araddr),
                 .s_axi_arready(m_axi_arready),
                 .s_axi_arvalid(m_axi_arvalid),
                 .s_axi_awaddr(m_axi_awaddr),
                 .s_axi_awready(m_axi_awready),
                 .s_axi_awvalid(m_axi_awvalid),
                 .s_axi_bready(m_axi_bready),
                 .s_axi_bvalid(m_axi_bvalid),
                 .s_axi_bresp(m_axi_bresp),
                 .s_axi_rdata(m_axi_rdata),
                 .s_axi_rready(m_axi_rready),
                 .s_axi_rresp(m_axi_rresp),
                 .s_axi_rvalid(m_axi_rvalid),
                 .s_axi_wdata(m_axi_wdata),
                 .s_axi_wready(m_axi_wready),
                 .s_axi_wstrb(m_axi_wstrb),
                 .s_axi_wvalid(m_axi_wvalid)
                 );
///////////////////////////////////////////////////////////////////////////
endmodule
		