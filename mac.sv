///////////////////////////////////////////////////////////////////////////////
//                   
// Title:             mac
// Semester:          ECE 551 Spring 2018
//
// Authors:           Lorne Miller, Devin Ott, Maddie Pine, Carter Swedal
// Lecturer's Name:   Younghyun Kim
// Group Number:      1
//
//////////////////////////////////////////////////////////////////////////////

module mac(a,b,clr,rst_n,clk,acc);

input clr,clk,rst_n;
input [7:0] a;
input [7:0] b;
output logic [25:0] acc;

logic [15:0]a_se;
logic [15:0]b_se;
logic [25:0]adder_result;
logic [15:0]mult_result;
logic [25:0]mult_result_sign_extended;

//accumulator reg
always@(posedge clk,negedge rst_n)begin
if(!rst_n) acc <= 16'h0000;
else if(clr) acc <= 16'h0000;
else acc<=adder_result;
end


//sign extended input A
assign a_se={{8{a[7]}},{a[7:0]}};
//sign extended input B
assign b_se={{8{b[7]}},{b[7:0]}};

//multiply result
assign mult_result=a_se*b_se;
//adder result of accumulator and current multiply result
assign adder_result=acc+mult_result_sign_extended;
assign mult_result_sign_extended = {{10{mult_result[15]}},mult_result};

endmodule