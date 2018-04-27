module RAM_INPUT_LAYER ( 
input data,  
input [9:0] addr,  
input we, clk,  
output q);  

// Declare the RAM variable 
 reg  ram[1023:0]; 
// Variable to hold the registered read address  
reg [9:0] addr_reg;  
initial begin
readmemh("ram_input_contents.txt", ram);  
end  
always @ (posedge clk)  
begin     
	if (we) 
	// Write        
		ram[addr] <= data;    
	addr_reg <= addr;  
end 
assign q = ram[addr_reg]; 

endmodule
