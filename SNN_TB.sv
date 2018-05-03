module SNN_TB();
//inputs to SNN
logic clk,sys_rst_n;

//PC to SNN and SNN to PC signals
logic pc_tx, pc_rx;
logic [7:0] led;
logic [7:0] pc_rx_data, pc_tx_data;
logic pc_tx_start;
logic pc_rx_rdy,pc_tx_rdy;



//pc_ROM signals
logic [9:0]pc_rom_addr;
logic [9:0]rom_out;
logic [3:0] file_num;

SNN snn_module(.clk(clk), .sys_rst_n(sys_rst_n), .led(led), .uart_tx(pc_rx), .uart_rx(pc_tx));

uart_rx rx_module(.clk(clk), .rst_n(sys_rst_n), .rx(pc_rx),.rx_rdy(pc_rx_rdy),.rx_data(pc_rx_data));
	
uart_tx tx_module(.clk(clk),.rst_n(sys_rst_n),.tx_start(pc_tx_start),.tx_data(pc_tx_data),.tx(pc_tx),.tx_rdy(pc_tx_rdy));

rom #(.DATA_WIDTH(1),.ADDR_WIDTH(10), .INIT_FILE("ram_input_contents_sample_6.txt")) rom0(.addr(pc_rom_addr),.clk(clk),.q(rom_out[0]));
rom #(.DATA_WIDTH(1),.ADDR_WIDTH(10), .INIT_FILE("ram_input_contents_sample_1.txt")) rom1(.addr(pc_rom_addr),.clk(clk),.q(rom_out[1]));
rom #(.DATA_WIDTH(1),.ADDR_WIDTH(10), .INIT_FILE("ram_input_contents_sample_2.txt")) rom2(.addr(pc_rom_addr),.clk(clk),.q(rom_out[2]));
rom #(.DATA_WIDTH(1),.ADDR_WIDTH(10), .INIT_FILE("ram_input_contents_sample_3.txt")) rom3(.addr(pc_rom_addr),.clk(clk),.q(rom_out[3]));
rom #(.DATA_WIDTH(1),.ADDR_WIDTH(10), .INIT_FILE("ram_input_contents_sample_4.txt")) rom4(.addr(pc_rom_addr),.clk(clk),.q(rom_out[4]));
rom #(.DATA_WIDTH(1),.ADDR_WIDTH(10), .INIT_FILE("ram_input_contents_sample_5.txt")) rom5(.addr(pc_rom_addr),.clk(clk),.q(rom_out[5]));
rom #(.DATA_WIDTH(1),.ADDR_WIDTH(10), .INIT_FILE("ram_input_contents_sample_6.txt")) rom6(.addr(pc_rom_addr),.clk(clk),.q(rom_out[6]));
rom #(.DATA_WIDTH(1),.ADDR_WIDTH(10), .INIT_FILE("ram_input_contents_sample_7.txt")) rom7(.addr(pc_rom_addr),.clk(clk),.q(rom_out[7]));
rom #(.DATA_WIDTH(1),.ADDR_WIDTH(10), .INIT_FILE("ram_input_contents_sample_8.txt")) rom8(.addr(pc_rom_addr),.clk(clk),.q(rom_out[8]));
rom #(.DATA_WIDTH(1),.ADDR_WIDTH(10), .INIT_FILE("ram_input_contents_sample_9.txt")) rom9(.addr(pc_rom_addr),.clk(clk),.q(rom_out[9]));


task get_next_byte;
  input reg [3:0]rom_index;
  reg [7:0] temp;
  reg [3:0] cnt;
  temp = 8'h00;
  
  for (cnt = 0; cnt < 4'd8; cnt = cnt + 4'd1) begin    
    @(posedge clk);
    #4;
    temp[cnt] = rom_out[rom_index];
    //$display("%d:  [%d] %d TEMP: %b\n",cnt, pc_rom_addr, rom_out, temp);
    pc_rom_addr += 10'd1;
    
  end
  //$display("temp: %x\n", temp);
  pc_tx_data = temp;
  @(posedge clk);
endtask

initial begin 
  clk=0;
  //reset core, tx, and rx
  //sys_rst_n=0;
  sys_rst_n=0;
  pc_tx_start=0;
  pc_tx_data=0;

  repeat (2) @(posedge clk); 
  sys_rst_n=1;
  repeat (2) @(posedge clk);
  for (file_num = 0; file_num < 1; file_num+= 1) begin
	  pc_rom_addr=0;
	  while (pc_rom_addr < 10'h310) begin
		get_next_byte(file_num);
		pc_tx_start = 1;
		@(posedge clk) pc_tx_start = 0;
		@(posedge pc_tx_rdy);
		@(posedge pc_tx_rdy);
	  end
	  @(posedge pc_rx_rdy) $display("PC received %x for file: %d\n", pc_rx_data, file_num);
  end
  $display("Time: %d\n", $time);
  $stop;
end

always begin
#5 clk=~clk;
end



endmodule

