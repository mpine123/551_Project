module tb_rom #(parameter DATA_WIDTH, parameter ADDR_WIDTH, parameter INIT_FILE)(
 input [(ADDR_WIDTH-1):0] addr,
 input clk,
 output reg [(DATA_WIDTH-1):0] q);
 // Declare the ROM variable
 reg  rom[2**ADDR_WIDTH-1:0];
 initial begin
 $readmemh(INIT_FILE, rom);
 end
 always @ (posedge clk)
 begin
 q <= rom[addr];
 end
endmodule 
