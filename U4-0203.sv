`timescale 1ns/1ps

module ripplecarry(
  input a,
  input b,
  input cin,
  output y,
  output cout
);
  
  assign y=a^b^cin;
  assign cout=(a&b)|((a^b)&cin);
  
endmodule

module add(
  input [3:0] a,
  input [3:0] b,
  input cin,
  output [3:0] y,
  output cout
);
  wire [2:0] c;
  
  ripplecarry a1(
    .a(a[0]),
    .b(b[0]),
    .cin(cin),
    .y(y[0]),
    .cout(c[0])
  );
  
  ripplecarry a2(
    .a(a[1]),
    .b(b[1]),
    .cin(c[0]),
    .y(y[1]),
    .cout(c[1])
  );
  
  ripplecarry a3(
    .a(a[2]),
    .b(b[2]),
    .cin(c[1]),
    .y(y[2]),
    .cout(c[2])
  );
  
  ripplecarry a4(
    .a(a[3]),
    .b(b[3]),
    .cin(c[2]),
    .y(y[3]),
    .cout(cout)
  );
  
endmodule

module add8(
  input [7:0] a,
  input [7:0] b,
  input cin,
  output [7:0] y,
  output cout
);
  wire c;
  
  add a1(
    .a(a[3:0]),
    .b(b[3:0]),
    .cin(cin),
    .y(y[3:0]),
    .cout(c)
  );
  
  add a2(
    .a(a[7:4]),
    .b(b[7:4]),
    .cin(c),
    .y(y[7:4]),
    .cout(cout)
  );
  
endmodule

module increment(
  input [7:0] a,
  output [7:0] y,
  output cout
);
  wire [6:0] c;
  assign y[0]=~a[0];
  assign c[0]=a[0];
  
  assign y[1]=a[1]^c[0];
  assign c[1]=a[1]&c[0];
  
  assign y[2]=a[2]^c[1];
  assign c[2]=a[2]&c[1];
  
  assign y[3]=a[3]^c[2];
  assign c[3]=a[3]&c[2];
  
  assign y[4]=a[4]^c[3];
  assign c[4]=a[4]&c[3];
  
  assign y[5]=a[5]^c[4];
  assign c[5]=a[5]&c[4];
  
  assign y[6]=a[6]^c[5];
  assign c[6]=a[6]&c[5];
  
  assign y[7]=a[7]^c[6];
  assign cout=a[7]&c[6];
endmodule

module ALU(
  input [3:0] a,
  input [3:0] b,
  input sub,
  output [3:0] y,
  output c
);
  
  wire [3:0] rb;
  wire cout;
  assign rb=b^{8{sub}};
  assign c=cout&~sub;
  
  add a1(
    .a(a),
    .b(rb),
    .cin(sub),
    .y(y),
    .cout(cout)
  );
  
endmodule



module CPU(
  input [7:0] in,
  input [3:0] ramin,
  input reset,
  input clk,
  output reg [7:0] out,
  output reg outOn,
  output reg [3:0] ramaddr,
  output reg [3:0] ramout,
  output reg ready,
  output reg ramclock,
  output reg ramwrite,
  output reg [8:0] SETPC
);
  reg [3:0] regs [3:0];
  wire [3:0] opcode, data;
  wire [1:0] op1,op2;
  assign opcode=in[7:4];
  assign data=in[3:0];
  assign op1=data[3:2];
  assign op2=data[1:0];
  
  reg Fprefix,Carry;
  reg [3:0] tempOp;
  
  reg [3:0] a,b;
  reg sub;
  wire [3:0] y;
  wire c;
  ALU alu(
    .a(a),
    .b(b),
    .sub(sub),
    .y(y),
    .c(c)
  );
  
  always @(posedge reset) begin
    regs[0]<=4'b0000;
    regs[1]<=4'b0000;
    regs[2]<=4'b0000;
    regs[3]<=4'b0000;
    a<=4'b0000;
    b<=4'b0000;
    out<=8'b00000000;
    sub<=0;
    Fprefix<=0;
    ramaddr<=4'b0000;
    ramout<=4'b0000;
    ramclock<=0;
    ready<=1;
    outOn<=0;
    SETPC<=9'b000000000;
    Carry<=0;
  end
  always @(posedge clk) begin
    ready<=0;
    out<=8'b00000000;
    ramwrite<=0;
    outOn<=0;
    SETPC[8]<=0;
    if (~Fprefix) begin
      if(~|opcode[3:2]) regs[opcode[1:0]]<=data;
      case(opcode)
        4'b0100: begin
          case(op1)
            2'b00: begin
              a<=regs[op2];
              b<=8'b00000001;
              sub<=0;
            end
            2'b01: begin
              a<=regs[op2];
              b<=8'b00000001;
              sub<=1;
            end
            2'b10: begin
              a<=regs[0];
              b<=8'b00000001;
              sub<=1;
            end
            2'b11: begin
              a<=regs[0];
              b<=regs[0];
            end
          endcase;
        end
        4'b0101: begin
          out<={regs[op1],regs[op2]};
          outOn<=1;
        end
        4'b0110: begin
          a<=regs[op1];
          b<=regs[op2];
          sub<=0;
        end
        4'b0111: begin
          a<=regs[op1];
          b<=regs[op2];
          sub<=1;
        end
        4'b1000: begin
          regs[op1]<=regs[op2];
        end
        4'b1001: begin
          SETPC<={1'b1,{4{data[3]}},data};
        end
        4'b1010: begin
          SETPC<={Carry,{4{data[3]}},data};
        end
        4'b1011: begin
          SETPC<={~Carry,{4{data[3]}},data};
        end
        4'b1100: begin
          a<=regs[op2];
          b<={3'b000,Carry};
          if (op1==2'b01) b<=4'b0001;
          sub<=~|op1;
        end
        4'b1101: begin
          case(regs[op2])
            4'b0000: regs[op1]<=regs[op1];
            4'b0001: regs[op1]<={regs[op1][2:0],1'b0};
            4'b0010: regs[op1]<={regs[op1][1:0],2'b00};
            4'b0011: regs[op1]<={regs[op1][0],3'b000};
            default: regs[op1]<=regs[0];
          endcase;
        end
        4'b1110: begin
          case(regs[op2])
            4'b0000: regs[op1]<=regs[op1];
            4'b0001: regs[op1]<={1'b0,regs[op1][3:1]};
            4'b0010: regs[op1]<={2'b00,regs[op1][3:2]};
            4'b0011: regs[op1]<={3'b000,regs[op1][3]};
            default: regs[op1]<=regs[0];
          endcase;
        end
        //////////////////////////////////////////////
      endcase;
    end else begin
      case(tempOp)
        4'b0000: begin
          out<={in};
          outOn<=1;
        end
        4'b0001: begin
          SETPC<={1'b1,in};
        end
        4'b0010: begin
          ramaddr<=data;
          ramwrite<=0;
          ramclock<=1;
        end
        4'b0011: begin
          SETPC<={Carry,in};
        end
        4'b0100: begin
          SETPC<={~Carry,in};
        end
        4'b0101: begin
          ramaddr<=opcode;
          ramout<=data;
          ramwrite<=1;
          ramclock<=1;
        end
        
        4'b0110: begin
          case(opcode[3:2])
            2'b00: regs[opcode[1:0]]<=regs[opcode[1:0]]^regs[op2];
            2'b01: regs[opcode[1:0]]<=regs[opcode[1:0]]~^regs[op2];
            default: begin
              ramaddr<=data;
              ramwrite<=0;
              ramclock<=1;
            end
          endcase;
        end
        4'b0111: begin
          case(opcode[3:2])
            2'b00: regs[opcode[1:0]]<=regs[opcode[1:0]]&regs[op2];
            2'b01: regs[opcode[1:0]]<=~(regs[opcode[1:0]]&regs[op2]);
            default: begin
              ramaddr<=data;
              ramwrite<=0;
              ramclock<=1;
            end
          endcase;
        end
        4'b1000: begin
          case(opcode[3:2])
            2'b00: regs[opcode[1:0]]<=regs[opcode[1:0]]|regs[op2];
            2'b01: regs[opcode[1:0]]<=~(regs[opcode[1:0]]|regs[op2]);
            default: begin
              ramaddr<=data;
              ramwrite<=0;
              ramclock<=1;
            end
          endcase;
        end
        
        
        4'b1001: begin
          Carry<=&(regs[opcode[1:0]]~^data);
        end
        4'b1010: begin
          ramaddr<=opcode;
          ramwrite<=0;
          ramclock<=1;
        end
        4'b1011: begin
          case(opcode[3:2])
            2'b00: begin
              ramaddr<=data;
              ramwrite<=0;
              ramclock<=1;
            end
            2'b01: begin
              ramaddr<=data;
              ramout<=regs[opcode[1:0]];
              ramwrite<=1;
              ramclock<=1;
            end
          endcase;
        end
        4'b1111: begin
          case(opcode)
            4'b0000: begin
              Carry<=&(regs[op1]~^regs[op2]);
            end
            4'b0001: begin
              a<=regs[op1];
              b<=regs[op2];
              sub<=0;
            end // see? no FF 2
            4'b0011: begin
              case(op2)
                2'b01: regs[op1]<={regs[op1][2:0],1'b0};
                2'b10: regs[op1]<={regs[op1][1:0],2'b00};
                2'b11: regs[op1]<={regs[op1][0],3'b000};
              endcase;
            end
            4'b0100: begin
              case(op2)
                2'b01: regs[op1]<={1'b0,regs[op1][3:1]};
                2'b10: regs[op1]<={2'b00,regs[op1][3:2]};
                2'b11: regs[op1]<={3'b000,regs[op1][3]};
              endcase;
            end
          endcase;
        end
      endcase;
    end
    regs[0]<=4'b0000;
  end
  
  always @(negedge clk) begin
    ready<=1;
    ramwrite<=0;
    ramclock<=0;
    SETPC[8]<=0;
    outOn<=0;
    Fprefix<=0;
    if (~Fprefix) begin
      case(opcode)
        4'b0100: begin
          regs[op2]<=y;
        end
        4'b0110: begin
          regs[op1]<=y;
          Carry<=c;
        end
        4'b0111: begin
          regs[op1]<=y;
          Carry<=c;
        end
        4'b1100: begin
          regs[op2]<=y;
          Carry<=(c&op1[0])|(Carry&~op1[0]);
        end
        4'b1111: begin
          Fprefix<=1;
          tempOp<=data;
        end
      endcase;
    end else begin
      case(tempOp)
        4'b0010: begin
          Carry<=&(regs[opcode[1:0]]~^ramin);
        end
        4'b0110: begin
          case(opcode[3:2])
            2'b10: regs[opcode[1:0]]<=regs[opcode[1:0]]^ramin;
            2'b11: regs[opcode[1:0]]<=~(regs[opcode[1:0]]^ramin);
          endcase;
        end
        4'b0111: begin
          case(opcode[3:2])
            2'b10: regs[opcode[1:0]]<=regs[opcode[1:0]]&ramin;
            2'b11: regs[opcode[1:0]]<=~(regs[opcode[1:0]]&ramin);
          endcase;
        end
        4'b1000: begin
          case(opcode[3:2])
            2'b10: regs[opcode[1:0]]<=regs[opcode[1:0]]|ramin;
            2'b11: regs[opcode[1:0]]<=~(regs[opcode[1:0]]|ramin);
          endcase;
        end
        4'b1010: begin
          Carry<=&(data~^ramin);
        end
        4'b1011: begin
          case(opcode[3:2])
            2'b00: begin
              regs[opcode[1:0]]<=ramin;
            end
          endcase;
        end
        4'b1111: begin
          case(opcode)
            4'b0001: begin
              regs[op1]<=y;
            end
          endcase;
        end
      endcase;
    end
  end
endmodule
// This table is outdated. Look in the manual for detailed information: https://docs.google.com/document/d/1lEEMphDVL4_5bmHpTN6oa5a97LpngJEEkrpWBhvYAWs/edit?usp=sharing
/*
First nybble is opcode, second nybble is operand(s). If opcode is 0xF, the second nybble becomes the opcode, and the next byte is the operand(s).
There are 20 registers in total: r0 is the zero register; writes are ignored, reads always return 0. r1-r3 are operating registers (you can perform various operations), a0-a15 are data registers, also known as RA (Random Access) registers; the only operations you can perform on them is read and write.
Code is read from the ROM, which is external and has its own program counter that can be modified by the CPU via JMP instructions.
x0: NOP; Literally 'MOV r0,imm4', but writes to r0 are ignored, so...
x1: MOV r1,imm4; Copy 4-bit immediate value into r1
x2: MOV r2,imm4; Copy 4-bit immediate value into r2
x3: MOV r3,imm4; Copy 4-bit immediate value into r3
x4 /0: INC reg; Increment register
x4 /1: DEC reg; Decrement register
x4 /2: MAX reg; Max out register (set to 0xF)
x4 /3: ZER reg; Zero out register (set to 0x0)
x5: OUT reg:reg; Output two register values
x6: ADD reg,reg; Add register to register
x7: SUB reg,reg; Subtract register by register
x8: MOV reg,reg; Copy 4-bit value from register to register
x9: JMP rel4
xA: JE/JC rel4
xB: JNE/JNC rel4
xC /0: CINC reg; Increment register if carry set
xC /1: CDEC reg; Decrement register if carry set
xC /2: SET reg; Set carry if register is zero, otherwise clear
xC /3: SETNC reg; Set carry if register is zero, otherwise do not clobber
xD: SHL reg,reg
xE: SHR reg,reg

xF: EXPAND; Prefix for next opcode set
xF0: OUT imm8; Output 8-bit immediate
xF1: JMP imm8; Relative jump to code location
xF2: CMP reg,mem; Compare register and RA register and set carry flag if equal
xF3: JE/JC imm8; Relative jump if last comparison was equal or last operation required a carry
xF4: JNE/JNC imm8; Relative jump if last comparison was not equal or last operation did not require a carry
xF5: MOV mem,imm4; Copy 4-bit immediate value into RA register
xF6 /0: XOR reg,reg; Bitwise XOR between two registers
xF6 /1: XNOR reg,reg; Bitwise XNOR between two registers
xF6 /2: XOR reg,mem; Bitwise XOR between a register and immediate value
xF6 /3: XNOR reg,mem; Bitwise XNOR between a register and immediate value
xF7 /0: AND reg,reg; Bitwise AND between two registers
xF7 /1: NAND reg,reg; Bitwise NAND between two registers
xF7 /2: AND reg,mem; Bitwise AND between a register and immediate value
xF7 /3: NAND reg,mem; Bitwise NAND between a register and immediate value
xF8 /0: OR reg,reg; Bitwise OR between two registers
xF8 /1: NOR reg,reg; Bitwise NOR between two registers
xF8 /2: OR reg,mem; Bitwise OR between a register and immediate value
xF8 /3: NOR reg,mem; Bitwise NOR between a register and immediate value
xF9: CMP reg,imm4
xFA: CMP mem,imm4
xFB /0: MOV reg,mem
xFB /1: MOV mem,reg

xFF: DOUBLE EXPAND; Prefix for next opcode set
xFF 0: CMP reg,reg; Compare two registers and set carry flag if equal
xFF 1: ADDNC reg,reg
xFF 3: SHL reg,imm2
xFF 4: SHR reg,imm2

32 current opcodes and 26 mnemonics
*/

module RAM(
  input [3:0] addr,
  input [3:0] data,
  input write,
  input clk,
  output [3:0] value
);
  reg [3:0] values [15:0];
  assign value=values[addr];
  always @(posedge clk) begin
    values[addr]<=(values[addr]&~{4{write}})|(data&{4{write}});
  end
endmodule

module ROM(
  input write,
  input clk,
  input reset,
  input [7:0] in,
  input ready,
  input [8:0] SETPC,
  output reg [7:0] out
);
  reg [7:0] PC;
  reg [7:0] memory [255:0];
  reg inc;
  wire [7:0] PCI;
  wire [7:0] PCA;
  increment count(
    .a(PC),
    .y(PCI)
  );
  add8 count2(
    .a(PC),
    .b(SETPC[7:0]),
    .cin(1'b0),
    .y(PCA)
  );
  always @(posedge reset) begin
    PC<=8'b00000000;
  end
  always @(posedge SETPC[8]) begin
    PC<=PCA;
  end
  always @(posedge clk) begin
    if (write) begin
      memory[PC]<=in;
      PC<=PCI;
    end
  end
  always @(posedge ready) begin
    if (~write) begin
      //$display("RUN %H",memory[PC]);
      out<=memory[PC];
      PC<=PCI;
    end
  end
endmodule

module top(
  input [7:0] in,
  input write,
  input reset,
  input clk,
  output [7:0] out,
  output outOn
);
  wire [3:0] ramdata,ramaddr,ramvalue;
  wire [7:0] databus;
  wire [8:0] SETPC;
  wire ramclock,ramwrite,ready;
  CPU cpu(
    .in(databus),
    .ramin(ramvalue),
    .reset(reset),
    .clk(clk),
    .out(out),
    .outOn(outOn),
    .ramaddr(ramaddr),
    .ramout(ramdata),
    .ready(ready),
    .ramclock(ramclock),
    .ramwrite(ramwrite),
    .SETPC(SETPC)
  );
  
  RAM ram(
    .addr(ramaddr),
    .data(ramdata),
    .write(ramwrite),
    .clk(ramclock),
    .value(ramvalue)
  );
  
  ROM rom(
    .write(write),
    .clk(clk),
    .reset(reset),
    .in(in),
    .ready(ready),
    .out(databus),
    .SETPC(SETPC)
  );
endmodule

/*
Example fibbonacci program
11 21 F0 01 51 8D 66 8B F4 FA F0 FF
MOV R1,1
MOV R2,1
OUT 1
loop:
OUT R1
MOV R3,R1
ADD R1,R2
MOV R2,R3
JNC loop
OUT 0xFF
*/

/*
8-bit addition program (OUTDATED)
F0 7B F0 43 30
1B 23 66 90 F5 01 31
17 24 66 67 D0 56 F0 F0

OUT 0x7B
OUT 0x43
MOV R3,0

MOV R1,0xB
MOV R2,0x3
ADD R1,R2
MOV A0,R1
JC cont
MOV R3,1
cont:

MOV R1,0x7
MOV R2,0x4
ADD R1,R2
ADD R1,R3
MOV R2,A0
OUT R1 R2
OUT 0xF0

*/

/*
Count to 100
31 59 67 F4 FC 42 F9 26 F4 F7 41 59 F9 14 F4 FA F0 FF
MOV R3,1
loop:
OUT R2:R1
ADD R1,R3
JNC loop
INC R2
CMP R2,6
JNE loop
loop2:
INC R1
OUT R2:R1
CMP R1,4
JNE loop2
OUT 0xFF
*/

/*
mul program: refer to manual for assembly

13 24 90 4D 4E 8E F9 30 F3 0A A1 D0 66 D1 F4 F6 42 F1 F3 59 F0 FF
*/

/*
15 27 FB 50 4D FB 41 loop F9 20 FB 30 F3 09 67 46 FB 30 CB FB 70 F1 F1 end 5D F0 FF

MOV R1,5
MOV R2,7

MOV A0,R1
ZER R1
MOV A1,R0

loop:
CMP R2,0
MOV R3,A0
JE end
ADD R1,R3
DEC R2
MOV R3,A0
CINC R3
MOV A0,R3
JMP loop
end:
OUT R3,R1
OUT 0xFF
*/
