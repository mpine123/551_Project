module ROM_ACT_FUNC_LUT_VALUES (  
input [(11-1):0] addr,  
input clk,   
output reg [(8-1):0] q);
  
// Declare the ROM variable  
reg [8-1:0] rom[2**11-1:0];  
initial begin
	readmemh("rom_act_func_lut_contents.txt", rom);  
end  
always @ (posedge clk)begin
	q <= rom[addr];  
end 
endmodule
