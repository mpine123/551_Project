module ROM_HIDDEN_LAYER (  
input [(15-1):0] addr,  
input clk,   
output reg [(8-1):0] q);
  
// Declare the ROM variable  
reg [8-1:0] rom[2**15-1:0];  
initial begin     
	readmemh("rom_hidden_weight_contents.txt", rom);  
end  
always @ (posedge clk)begin
	q <= rom[addr];  
end 
endmodule
