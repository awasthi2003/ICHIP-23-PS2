`timescale 1ns/1ps
module CalC(x,y,zx,nx,zy,ny,f,no,o,zr,ng);
input [15:0] x,y;
input zx,nx,zy,ny,f,no;
output [15:0] o;
output zr,ng;
wire [15:0] x1,y1,x2,y2,z1;

assign x1 = zx ? 0 : x;
assign x2 = nx ? ~x1 : x1;
assign y1 = zy ? 0 : y;
assign y2 = ny ? ~y1 : y1;
assign z1 = f ? (x2+y2): (x2&y2);
assign  o = no ? ~z1 : z1;
assign zr = ~(|o);
assign ng = o[15];
endmodule


// memory module
module memo(r,ad,dt_in,dt_out);
input [9:0] ad;
input r,w;
reg clk=0;
always
 #1 clk <= ~clk;
input [15:0] dt_in;
output reg [15:0] dt_out;
reg [15:0] mem[1023:0];
always @(posedge clk)begin
    if(r==1)
    dt_out = mem[ad];
    else mem[ad] = dt_in;
end

endmodule






// Main module
module CPU(input clk);

// registers used in cpu
reg [9:0] pc = 0,mar=0;    // mar is register used for addressing memory.
reg [15:0] ir=0,ac=0,dr=0;  // dr is register used to store temporary data used as y in calc.
reg f=0,s=1;               // f is flip flop used to distinguish between fetch and execute cycle.f=0 means fetch cycle and f=1 means execute cycle.
                            // s is a flip flop used to stop processing when end of program is reached by changing from 1 to 0.
                        


//2 bit counter with synchronous clear
parameter countmax=3;
integer counter;
wire t0,t1,t2,t3,t4,clr;
assign t0 = counter==0;
assign t1 = counter==1;
assign t2 = counter==2;
assign t3 = counter==3;
assign clr = (nf&t2&((~mode) | c2)) | (nf&t3) | (f&t0&(opcode==19)) | (f&t1);   
always @(posedge (clk&s)) begin
    if(clr | (counter==countmax))
    counter = 0;
    else 
    counter = counter +1 ;
end




wire read;
assign read = ~(f&t0&(opcode==19));
wire nf;              // nf is taken for simplicity for ~f
wire [4:0] opcode;
wire mode;            
reg [15:0]bus;        // 15 bit bus connected to all registers.
wire ldar,ldpc,ldac,ldir,ldf,lddr,incpc;  // these are loads to various registers and incpc is increment pc.
assign incpc = nf&t1;
wire c1,c2;
assign c1 = (opcode==20)|((opcode==21)&(ac==0))| ((opcode==22)&ac[15]); 
assign c2 = ((opcode==21)&(ac!=0))|((opcode==22)&(!ac[15]));

assign mode = ir[15];
assign opcode = ir[14:10];
assign nf = ~f;
wire [15:0] dt_out;          // dt-out is data out from memory.


reg [5:0] c;       //control variables
always @(opcode) begin
if(opcode==0) c= 6'b101010;
if(opcode==1) c= 6'b111111;
if(opcode==2) c= 6'b111010;
if(opcode==3) c= 6'b001100;
if(opcode==4) c= 6'b110000;
if(opcode==5) c= 6'b001101;
if(opcode==6) c= 6'b110001;
if(opcode==7) c= 6'b001111;
if(opcode==8) c= 6'b110011;
if(opcode==9) c= 6'b011111;
if(opcode==10) c= 6'b110111;
if(opcode==11) c= 6'b001110;
if(opcode==12) c= 6'b110010;
if(opcode==13) c= 6'b000010;
if(opcode==14) c= 6'b010011;
if(opcode==15) c= 6'b000111;
if(opcode==16) c= 6'b000000;
if(opcode==17) c= 6'b010101;
if(opcode>=18) c= 6'b001100;
end


// assign statements
wire zr,ng;
wire [15:0] aluout;                  // aluout is output of CalC

CalC cal(ac,dr,c[5],c[4],c[3],c[2],c[1],c[0],aluout,zr,ng);
memo mem(read,mar,bus,dt_out);        // memory

// assigning values to loads of all registers used.
assign ldar = (nf&t0)|(nf&t2&mode)|(nf&t2&(~c1))|(nf&t3&(~c1));
assign ldpc = (nf&t2&c1&(~mode)) | (nf&t3&c1);
assign ldac = (f&t1&(opcode<=18));
assign ldir = nf&t1;
assign lddr = (f&t0&(opcode!=19));
assign ldf = (nf&t2&(~mode)&(opcode<=19)) | (nf&t3&(~c1)) | (f&t0&(opcode==19)) | (f&t1);
assign lds = nf&t2&(opcode==23);

// assigning values to bus
always @(ac,mar,pc,ir,dt_out,counter,aluout,f) begin
    if(nf&t0)
    bus = pc;
    if(nf&t2&((~c1)|mode)) 
    bus = ir;
    if((nf&(t1|t3|(t2&(~mode)&c1)))|(f&t0&(opcode!=19)))
    bus=dt_out;
   if(f&t0&(opcode==19))
   bus = ac;
    if(f&t1&(opcode<=17))
    bus=aluout;
    if(f&t1&(opcode==18))
    bus = dr;

end


always @(posedge clk) begin
    if(ldac)
    ac = bus;
    if(ldar)
    mar = bus[9:0];
    if(ldir)
    ir = bus;
    if(ldpc)
    pc = bus[9:0];
    if(incpc)
    pc = pc+1;
    if(ldf)
    f = ~f;
    if(lddr)
    dr = bus;
    if(lds)
    s=0;
end
endmodule