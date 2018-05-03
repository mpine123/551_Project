module rom #(parameter DATA_WIDTH = 8, parameter ADDR_WIDTH = 15, parameter INIT_FILE = "devin.txt")(
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
