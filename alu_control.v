module ALU_Control (
    input wire is_immediate_i,
    input wire [1:0] ALU_CO_i,
    input wire [6:0] FUNC7_i,
    input wire [2:0] FUNC3_i,
    output reg [3:0] ALU_OP_o
);

localparam LOAD_STORE = 2'b00; // Tipo I e S
localparam BRANCH = 2'b01;     // Tipo B
localparam ALU = 2'b10;        // Tipo I e R
localparam INVALID = 2'b11;

//Tabela de operações ULA
//  AND             = 4'b0000; 111_0000000_0110011
//  OR              = 4'b0001; 110_0000000_0110011
//  ADD             = 4'b0010; 000_xxxxxxx_0110011
//  SUB             = 4'b1010; 000_0100000_0110011
//  GREATER_EQUAL   = 4'b1100; -----------
//  GREATER_EQUAL_U = 4'b1101; -----------
//  SLT             = 4'b1110; 010_0000000_0110011
//  SLT_U           = 4'b1111; 011_0000000_0110011
//  SHIFT_LEFT      = 4'b0100; 001_0000000_0110011
//  SHIFT_RIGHT     = 4'b0101; 101_0000000_0110011
//  SHIFT_RIGHT_A   = 4'b0111; 101_0100000_0110011
//  XOR             = 4'b1000; 100_0000000_0110011
//  NOR             = 4'b1001; ----------
//  EQUAL           = 4'b0011; ----------


//Operacoes ULA
// ALU_CO_i = 00

/*
0000000 rs2 rs1 000 rd 0110011 ADD
0100000 rs2 rs1 000 rd 0110011 SUB
0000000 rs2 rs1 001 rd 0110011 SLL
0000000 rs2 rs1 010 rd 0110011 SLT
0000000 rs2 rs1 011 rd 0110011 SLTU
0000000 rs2 rs1 100 rd 0110011 XOR
0000000 rs2 rs1 101 rd 0110011 SRL
0100000 rs2 rs1 101 rd 0110011 SRA
0000000 rs2 rs1 110 rd 0110011 OR
0000000 rs2 rs1 111 rd 0110011 AND

Imediato
imm[11:0] rs1 000 rd 0010011 ADDI
imm[11:0] rs1 010 rd 0010011 SLTI
imm[11:0] rs1 011 rd 0010011 SLTIU
imm[11:0] rs1 100 rd 0010011 XORI
imm[11:0] rs1 110 rd 0010011 ORI
imm[11:0] rs1 111 rd 0010011 ANDI
0000000 shamt rs1 001 rd 0010011 SLLI
0000000 shamt rs1 101 rd 0010011 SRLI
0100000 shamt rs1 101 rd 0010011 SRAI
*/


// Operações Load & STORE
//Operacoes LOAD STORE são todas somas
// ALU_CO_i = 01

//imm[11:0] rs1 000 rd 0000011 LB
//imm[11:0] rs1 001 rd 0000011 LH
//imm[11:0] rs1 010 rd 0000011 LW
//imm[11:0] rs1 100 rd 0000011 LBU
//imm[11:0] rs1 101 rd 0000011 LHU

//imm[11:5] rs2 rs1 000 imm[4:0] 0100011 SB
//imm[11:5] rs2 rs1 001 imm[4:0] 0100011 SH
//imm[11:5] rs2 rs1 010 imm[4:0] 0100011 SW


//Operacoes Branch
// ALU_CO_i = 10

// imm[12|10:5] rs2 rs1 000 imm[4:1|11] 1100011 BEQ
// imm[12|10:5] rs2 rs1 001 imm[4:1|11] 1100011 BNE
// imm[12|10:5] rs2 rs1 100 imm[4:1|11] 1100011 BLT
// imm[12|10:5] rs2 rs1 101 imm[4:1|11] 1100011 BGE
// imm[12|10:5] rs2 rs1 110 imm[4:1|11] 1100011 BLTU
// imm[12|10:5] rs2 rs1 111 imm[4:1|11] 1100011 BGEU

always @(*) begin
    case (ALU_CO_i)

        LOAD_STORE : begin
            case (FUNC3_i)
                default: ALU_OP_o = 4'b0010;
            endcase
        end

        BRANCH : begin
            case (FUNC3_i)
                3'b000: ALU_OP_o = 4'b0011; //BEQ Se for Igual
                3'b001: ALU_OP_o = 4'b0011; //BNE Se for Diferente
                3'b100: ALU_OP_o = 4'b1110; //BLT Se for Menor
                3'b101: ALU_OP_o = 4'b1100; //BGE Se for Maior ou Igual
                3'b110: ALU_OP_o = 4'b1111; //BLTU Se for Menor Unsigned
                3'b111: ALU_OP_o = 4'b1101; //BGEU Se for Maior Igual Unsigned
                default: ALU_OP_o = 4'b0000;
            endcase
        end 
        
        ALU : begin
            case (FUNC3_i)
                3'b000: begin // Pode ser soma ou subtracao dependendo do func7
                    if (is_immediate_i) begin  // Se for de imediato só pode ser ADD
                        ALU_OP_o =  4'b0010;
                    end
                    else begin 
                        if (FUNC7_i == 7'b0000000) begin // Func7 = 0 ADD
                            ALU_OP_o =  4'b0010;  // ADD     
                        end
                        else begin
                            ALU_OP_o = 4'b1010; // SUB
                        end
                    end
                end
                3'b001: ALU_OP_o = 4'b0100; // SLL
                3'b010: ALU_OP_o = 4'b1110; // SLT
                3'b011: ALU_OP_o = 4'b1111; // SLTU
                3'b100: ALU_OP_o = 4'b1000; // XOR
                3'b101: begin 
                    if (FUNC7_i == 7'b0000000) begin  // SRL
                        ALU_OP_o = 4'b0101;
                    end
                    else begin // SRA
                        ALU_OP_o = 4'b0111;
                    end
                end
                3'b110: ALU_OP_o = 4'b0001; // OR
                3'b111: ALU_OP_o = 4'b0000; // AND
                default: ALU_OP_o = 4'b0000;
            endcase
        end 

        default: ALU_OP_o = 4'b0000;

    endcase
end


endmodule
