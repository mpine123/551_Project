///////////////////////////////////////////////////////////////////////////////
//                   
// Title:             rom
// Semester:          ECE 551 Spring 2018
//
// Authors:           Lorne Miller, Devin Ott, Maddie Pine, Carter Swedal
// Lecturer's Name:   Younghyun Kim
// Group Number:      1
//
//////////////////////////////////////////////////////////////////////////////

module rom #(parameter DATA_WIDTH, parameter ADDR_WIDTH, parameter INIT_FILE)(
 input [(ADDR_WIDTH-1):0] addr,
 input clk,
 output reg [(DATA_WIDTH-1):0] q);
 // Declare the ROM variable
 reg [DATA_WIDTH-1:0] rom[2**ADDR_WIDTH-1:0];
 initial begin
 $readmemh(INIT_FILE, rom);
 end
 always @ (posedge clk)
 begin
 q <= rom[addr];
 end
endmodule 
