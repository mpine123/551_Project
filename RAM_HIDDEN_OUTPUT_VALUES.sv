module RAM_HIDDEN_OUTPUT_VALUES (  
input [7:0] data,  
input [4:0] addr,  
input we, clk,  
output [7:0] q);  

// Declare the RAM variable 
 reg [7:0] ram[31:0]; 
// Variable to hold the registered read address  
reg [4:0] addr_reg;  
initial begin
readmemh("ram_hidden_contents.txt", ram);  
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
