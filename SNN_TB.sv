///////////////////////////////////////////////////////////////////////////////
//                   
// Title:             SNN_TB
// Semester:          ECE 551 Spring 2018
//
// Authors:           Lorne Miller, Devin Ott, Maddie Pine, Carter Swedal
// Lecturer's Name:   Younghyun Kim
// Group Number:      1
//
//////////////////////////////////////////////////////////////////////////////

module SNN_TB();
//inputs to SNN
logic clk,sys_rst_n,uart_rx;

//outputs to SNN
logic uart_tx;
logic [7:0] led;
logic [1023:0] digit_pixels;//zero,one,two,three,four,five,six,seven,eight,nine,ten
reg ram[2**10-1:0];

//uart signals
logic [7:0] rx_data,tx_data;
logic [3:0]bit_cnt;
logic tx_start;

//ROM signals
logic [9:0]addr;
logic q;

SNN snn_module(clk, sys_rst_n, led, uart_tx, uart_rx);

	uart_rx rx_module(.clk(clk), .rst_n(sys_rst_n), .rx(uart_tx),.rx_rdy(),.rx_data(rx_data));
	
	uart_tx tx_module(.clk(clk),.rst_n(sys_rst_n),.tx_start(tx_start),.tx_data(tx_data),.tx(uart_rx),.tx_rdy());
//ram #(.DATA_WIDTH(1), .ADDR_WIDTH(10), .INIT_FILE("ram_input_contents_sample_0.txt")) inputValuesDUT(.q(q_input),.clk(clk),.we(we),.data(data),.addr(addr_input_unit));	
rom #(.DATA_WIDTH(8),.ADDR_WIDTH(10), .INIT_FILE("ram_input_contents_sample_0.txt")) Activation_Function(.addr(addr),.clk(clk),.q(data));
initial begin 
clk=0;
//reset core, tx, and rx
//sys_rst_n=0;
uart_rx=1;
addr=0;
send_data();
$stop;
//#5 sys_rst_n=1;
end

always begin
#5 clk=~clk;
end

task send_data;//(input string filename);
	//#(parameter string )
	//input reg [1023:0] digit_pixels;
	
	//$readmemh("ram_input_contents_sample_0.txt", ram);  
	sys_rst_n=0;
	@(posedge clk) sys_rst_n=1;
	
	//transmits 8 pixels at a time, so 98 sends will be needed
	for(int count=0;count<784;count+=8)begin
	//data=ram[count<<8'hFF];
	addr=count;
	monitor_full_send();
	end

endtask

task monitor_full_send;
//rst_n=0;
//@(posedge clk) rst_n=1;
  tx_data = data;
  tx_start = 1'b1;
   
  //monitor start
  bit_cnt = 4'hF;
  monitor_tx(bit_cnt);
  
  //monitor data
  for (bit_cnt = 4'h0; bit_cnt < 4'h8; bit_cnt = bit_cnt + 1) begin
    monitor_tx(bit_cnt);
  end
  
  //monitor end
  bit_cnt = 4'hE;
  monitor_tx(bit_cnt);
endtask

task monitor_tx;
  input reg [3:0] bit_pos;

  if (bit_pos == 4'hF) begin	//check start bit for 1 baud
	repeat (2604) begin
	  @(posedge clk);
	 // assert(tx == 1'b0);
	end
	tx_start = 1'b0;
  end 
  else if (bit_pos == 4'hE) begin //check stop bit for 1 baud
    repeat (2604) begin
	  @(posedge clk);
	  //assert(tx == 1'b1);
	end
	//assert(tx_rdy == 1'b1);
  end
  else begin	//check data bit for 1 baud
    repeat (2604) begin
	  @(posedge clk);
	  //assert(tx == data[bit_pos]);
	end
  end 
endtask

endmodule

