
module SNN(clk, sys_rst_n, led, uart_tx, uart_rx);
		
	input clk;			      // 50MHz clock
	input sys_rst_n;			// Unsynched reset from push button. Needs to be synchronized.
	output reg [7:0] led;	// Drives LEDs of DE0 nano board
	
	//UART variables
	input uart_rx;
	output uart_tx;

	logic rst_n;				 	// Synchronized active low reset
	logic uart_rx_ff, uart_rx_synch;
	logic [7:0]rx_data;
	
	logic tx_rdy,rx_rdy;
	
	//snn_core variables
	logic[9:0]addr_input_unit;
	logic [3:0] digit;
	logic done,start;
	logic snn_core_q_input;
	
	//state machine variables
	typedef enum reg[2:0] {IDLE,WRITE_BYTE,WAIT_RX,PREDICT_DIGIT,TRANSMITTING}state_t;
	state_t state,next_state;
	logic clr_pixel_cnt,inc_pixel_cnt,update_led,transmit,store_rx,bit_cnt_clr,we;
	logic [9:0] pixel_count;
	logic [9:0] address;
	logic [7:0] pixel_values; //data to be stored in RAM
	logic [3:0] bit_cnt; //Counter for storing 8 bits at a time to RAM
	logic data; //bit stored into RAM
	logic full_byte; //when bit count reaches 8
	logic full_pixel_cnt; //when pixel count reaches 784
	/******************************************************
	Reset synchronizer
	******************************************************/
	rst_synch i_rst_synch(.clk(clk), .sys_rst_n(sys_rst_n), .rst_n(rst_n));

	// Instantiate UART_RX and UART_TX and connect them below
	// For UART_RX, use "uart_rx_synch", which is synchronized, not "uart_rx".
	
	uart_rx rx_module(.clk(clk), .rst_n(sys_rst_n), .rx(uart_rx_synch),.rx_rdy(rx_rdy),.rx_data(rx_data));
						           //ram_input_contents.txt
	ram #(.DATA_WIDTH(1), .ADDR_WIDTH(10), .INIT_FILE("ram_input_contents_x.txt")) inputValuesDUT(.q(snn_core_q_input),.clk(clk),.we(we),.data(data),.addr(address));	
	
	//RAM_INPUT_LAYER input_layer(.data(pixel_values),.addr(address_value),.we(we),.clk(clk),.q(snn_core_q_input));
	
	snn_core snn_core_module(.start(start),.rst_n(sys_rst_n),.clk(clk),.q_input(snn_core_q_input),.addr_input_unit(addr_input_unit),.digit(digit),.done(done));	
	
	uart_tx tx_module(.clk(clk),.rst_n(sys_rst_n),.tx_start(transmit),.tx_data({4'h0,digit[3:0]}),.tx(uart_tx),.tx_rdy(tx_rdy));
	

	
	/******************************************************
	UART
	******************************************************/
	
	// Declare wires below
	
	// Double flop RX for meta-stability reasons
	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n) begin
		uart_rx_ff <= 1'b1;
		uart_rx_synch <= 1'b1;
	end else begin
	  uart_rx_ff <= uart_rx;
	  uart_rx_synch <= uart_rx_ff;
	end
	
	//state reg
	always@(posedge clk,negedge rst_n) begin
		if(!rst_n) begin
			state<=IDLE;
		end
		else 
			state<=next_state;
	end

	//Pixel Count Register
	always@(posedge clk,negedge rst_n) begin
		if(!rst_n) begin
			pixel_count<=10'h000;
		end
		else if(clr_pixel_cnt) begin
			pixel_count<=10'h000;
		end
		else if(inc_pixel_cnt) begin
			pixel_count <= pixel_count + 1;
		end
		else begin
			pixel_count <= pixel_count;
		end
	end
	
		//Pixel Values Register
	always@(posedge clk,negedge rst_n) begin
		if(!rst_n) begin
			pixel_values<=8'h00;
		end
		else if(store_rx) begin
			pixel_values<=rx_data;
		end
		else begin
			pixel_values <= pixel_values;
		end
	end
	
			//Bit Count Register
	always@(posedge clk,negedge rst_n) begin
		if(!rst_n) begin
			bit_cnt<=4'h0;
		end
		else if(bit_cnt_clr) begin
			bit_cnt<=4'h0;
		end
		else begin
			bit_cnt <= bit_cnt+1;
		end
	end
	
	/******************************************************
	LED
	******************************************************/
	always_ff @(posedge clk) begin 
	if(!rst_n) led<=8'h00; 
	else if(update_led) begin 
		
		led <= digit;
		end
	
	else begin
	led <= led;
	end
	end
	
	//state machine
	
	always_comb begin
		next_state=IDLE;
		clr_pixel_cnt=1;
		inc_pixel_cnt=0;
		update_led=0;
		transmit=0;
		store_rx=0;
		bit_cnt_clr=1;
		we=0;
		start=0;
		//clr_pixel_cnt,inc_pixel_cnt,update_led,transmit,store_rx,bit_cnt_clr,we;
		
	case(state)
		IDLE: begin
			if(!rx_rdy) begin
				next_state=IDLE;
			end
			else begin
				next_state=WRITE_BYTE;
				store_rx=1;
			end
		end
		
		WRITE_BYTE : begin
			if(full_byte && !full_pixel_cnt) begin
				clr_pixel_cnt=0;
				inc_pixel_cnt=1;
				inc_pixel_cnt=1;
				we=1;
				next_state = WAIT_RX;
			end
			else if(full_byte && full_pixel_cnt) begin
				start=1;
				inc_pixel_cnt=1;
				we=1;
				next_state = PREDICT_DIGIT;
			end
			else begin
				bit_cnt_clr=0;
				clr_pixel_cnt=0;
				we=1;
				inc_pixel_cnt=1;
				next_state = WRITE_BYTE;
			end
		end
		
		WAIT_RX : begin
			if(rx_rdy) begin
				store_rx=1;
				clr_pixel_cnt=0;
				next_state = WRITE_BYTE;
			end
			//!rx_rdy
			else begin
				clr_pixel_cnt=0;
				next_state=WAIT_RX;
			end
		end
		PREDICT_DIGIT: begin
			if(!done) begin
			next_state=PREDICT_DIGIT;
			end 
			else begin
			next_state=TRANSMITTING;
			transmit=1;
			update_led=1;
			end
		end
		
		TRANSMITTING: begin 
			if(!tx_rdy) begin
				next_state=TRANSMITTING;
			end
			else begin 
			next_state=IDLE;
			end
		end
		
		default: begin 
		end
		endcase
	end
	
	//logic to decide the input of the RAM unit
	assign address=(state==PREDICT_DIGIT)?addr_input_unit:pixel_count;
	assign data=pixel_values[bit_cnt];
	assign full_byte = (bit_cnt == 4'h7);
	assign full_pixel_cnt = (pixel_count == 10'h30F);
	
endmodule
