module SNN_TB();
//inputs to SNN
logic clk,sys_rst_n,uart_rx;

//outputs to SNN
logic uart_tx;
logic [7:0] led,data;
logic [1023:0] digit_pixels;//zero,one,two,three,four,five,six,seven,eight,nine,ten

//uart signals
logic [7:0] rx_data,tx_data;
logic [3:0]bit_cnt;
logic tx_start;
SNN snn_module(clk, sys_rst_n, led, uart_tx, uart_rx);

	uart_rx rx_module(.clk(clk), .rst_n(sys_rst_n), .rx(uart_tx),.rx_rdy(),.rx_data(rx_data));
	
	uart_tx tx_module(.clk(clk),.rst_n(sys_rst_n),.tx_start(tx_start),.tx_data(tx_data),.tx(uart_rx),.tx_rdy());

initial begin 
clk=0;
//reset core, tx, and rx
//sys_rst_n=0;
uart_rx=1;
send_data("ram_input_contents_sample_0.txt");
//#5 sys_rst_n=1;
end

always begin
#5 clk=~clk;
end

task send_data;
	//input reg [1023:0] digit_pixels;
	parameter string filename;
	readmemh(filename, digit_pixels);  
	sys_rst_n=0;
	@(posedge clk) sys_rst_n=1;
	
	//transmits 8 pixels at a time, so 98 sends will be needed
	for(int count=0;count<784/8;count++)begin
	data=digit_pixels[count+3'h7:count];
	monitor_full_send();
	end
  /* reg [3:0] count;
  rx = 1'b0; //start bit

  repeat (2604) @(posedge clk);

  for (count = 4'b0; count < 4'h8; count = count + 1) begin  
    rx = data[count];
    repeat (2604) @(posedge clk);
  end

  rx = 1'b1;
  repeat (2604) @(posedge clk); */
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
