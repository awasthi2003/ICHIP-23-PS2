`timescale 1ns/1ps
`include "ichip2.v"
module test;
reg clk=0;
always
 #5 clk <= ~clk;
CPU cpu1(clk);
// reg [15:0] mem[1023:0];
integer i,file;
initial begin
     # 6 cpu1.counter = 0;
end
initial begin
    file = $fopen("output.txt");
    $dumpfile("ichip2.vcd");
    $dumpvars(0,test);
    $readmemh("Program.txt",cpu1.mem.mem,0,29);
    $readmemh("Data.txt",cpu1.mem.mem,401,430);
end
always @(cpu1.s) begin
    if(cpu1.s==0)
    begin
        for(i=401;i<=430;i=i+1)
    $fdisplay(file,"%h",cpu1.mem.mem[i]);
    #1 $finish;
    end
    
end
endmodule
// iverilog -o ichip2_tb.vvp ichip2_tb.v
// vvp ichip2_tb.vvp