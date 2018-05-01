
module SNN(clk, sys_rst_n, led, uart_tx, uart_rx);
		
	input clk;			      // 50MHz clock
	input sys_rst_n;			// Unsynched reset from push button. Needs to be synchronized.
	output reg [7:0] led;	// Drives LEDs of DE0 nano board
	
	input uart_rx;
	output uart_tx;

	logic rst_n;				 	// Synchronized active low reset
	logic uart_rx_ff, uart_rx_synch;
	
	
	logic tx_rdy,rx_rdy;
	
	//snn_core variables
	logic[9:0]addr_input_unit;
	logic [7:0] digit;
	logic we,done;
	
	//state machine variables
	typedef enum reg[1:0] {IDLE,READ_DIGIT,PREDICIT_DIGIT,TRANSMITTING}state_t;
	state_t state,next_state;
	logic clr_pixel_cnt_n,inc_addr,update_led,transmit;
	logic [9:0] pixel_count;
	logic [9:0] address;
	logic [7:0] pixel_values; //data to be stored in RAM
	/******************************************************
	Reset synchronizer
	******************************************************/
	rst_synch i_rst_synch(.clk(clk), .sys_rst_n(sys_rst_n), .rst_n(rst_n));
	
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
	
	
	// Instantiate UART_RX and UART_TX and connect them below
	// For UART_RX, use "uart_rx_synch", which is synchronized, not "uart_rx".
	
	uart_rx rx_module(.clk(clk), .rst_n(sys_rst_n), .rx(uart_rx_synch),.rx_rdy(rx_rdy),.rx_data(pixel_values));

	ram #(.DATA_WIDTH(1), .ADDR_WIDTH(10), .INIT_FILE("ram_input_contents.txt")) inputValuesDUT(.q(q_input),.clk(clk),.we(we),.data(data),.addr(addr_input_unit));	
	
	//RAM_INPUT_LAYER input_layer(.data(pixel_values),.addr(address_value),.we(we),.clk(clk),.q(snn_core_q_input));
	
	snn_core snn_core_module(.start(start),.rst_n(sys_rst_n),.clk(clk),.q_input(snn_core_q_input),.addr_input_unit(addr_input_unit),.digit(digit),.done(done));	
	
	uart_tx tx_module(.clk(clk),.rst_n(sys_rst_n),.tx_start(transmit),.tx_data(digit),.tx(uart_tx),.tx_rdy(tx_rdy));
	
	//state machine
	
	always_comb begin
		clr_pixel_cnt_n=0;
		inc_addr=0;
		update_led=0;
		transmit=0;
		next_state=IDLE;
	case(state)
		IDLE: begin
			if(!rx_rdy) begin
				next_state=IDLE;
			end
			else begin
				next_state=READ_DIGIT;
				we=1;
				inc_addr=1;
				//clr_pixel_cnt_n=1;
			end
		end
		
		READ_DIGIT: begin
		//98 in hex
			clr_pixel_cnt_n=1;
			if(pixel_count < 7'h62) begin
				next_state=READ_DIGIT;
			end
			else if(pixel_count < 7'h62 && rx_rdy) begin
			next_state=READ_DIGIT;
			we=1;
			inc_addr=1;
			end
			else begin
				next_state=PREDICIT_DIGIT;
			end 
			
		end
		
		PREDICIT_DIGIT: begin
			if(!done) begin
			next_state=PREDICIT_DIGIT;
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
	always_comb begin
		if(state == IDLE || state == READ_DIGIT) begin
		address=pixel_count;
		end
		else begin
		address=addr_input_unit;
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
endmodule
