module ROM_OUTPUT_LAYER (  
input [3:0] addr,  
input clk,   
output reg [7:0] q);
  
// Declare the ROM variable  
reg [7:0] rom[15:0];  
initial begin
	readmemh("rom_output_weight_contents.txt", rom);  
end  
always @ (posedge clk)begin
	q <= rom[addr];  
end 
endmodule
