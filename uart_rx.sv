///////////////////////////////////////////////////////////////////////////////
//                   
// Title:             uart_rx
// Semester:          ECE 551 Spring 2018
//
// Authors:           Lorne Miller, Devin Ott, Maddie Pine, Carter Swedal
// Lecturer's Name:   Younghyun Kim
// Group Number:      1
//
//////////////////////////////////////////////////////////////////////////////

module uart_rx(clk,rst_n, rx, rx_rdy,rx_data);
input rx,clk,rst_n;
output rx_rdy;
output logic [7:0] rx_data;
typedef enum reg [1:0]{IDLE,FRONT_PORCH,RX,BACK_PORCH}state_t;

state_t state, next_state;

reg [11:0] baudCounter;
reg [2:0] cnt;

logic half_baud, full_baud, shift_reg_full, shift, clr_baud, clr_shift_reg;

//state reg's always block
always_ff @(posedge clk, negedge rst_n) begin

	if(!rst_n)begin
		state <= IDLE;
	end else begin
		state <= next_state;
	end

end


//rx_data reg's always block
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n )begin
		rx_data <= 8'h00;
	end 
	else if(clr_shift_reg)begin
		rx_data <= 8'h00;
	end
	else begin
		if(shift)begin
			rx_data <= {rx, rx_data[7:1]};
		end else begin
			rx_data <= rx_data;
		end
	end

end

//baudCounter reg's always block
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n)begin
		baudCounter <= 12'h000;
	end 
	else if(clr_baud)begin
		baudCounter <= 12'h000;
	end
	else begin
		baudCounter <= baudCounter + 1;
	end

end

//cnt reg's always block
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n) begin
		cnt <= 3'b000;
	end 
	else if(clr_shift_reg) begin
		cnt <= 3'b000;
	end
	else begin 
		if(shift)begin
			cnt <= cnt + 1;
		end else begin
			cnt <= cnt;	
		end
	end

end

always_comb begin
	//rx_rdy = 0;
	clr_baud = 0;
	clr_shift_reg = 0;
	next_state = IDLE;
	shift=0;
	case(state)
		IDLE: begin
			if(!rx)begin
				next_state = FRONT_PORCH;
			end else begin
				clr_baud = 1;
				clr_shift_reg = 1;
			end
		end
		FRONT_PORCH: begin
			if(half_baud)begin
				next_state = RX;
				clr_baud = 1;
				clr_shift_reg = 1;
			end else begin
				clr_shift_reg = 1;
				next_state = FRONT_PORCH;
			end
		end
		RX: begin
			if(~shift_reg_full && full_baud)begin
				next_state = RX;
				clr_baud = 1;
				shift=1;
			end else if(shift_reg_full && full_baud) begin
				clr_baud = 1;
				next_state = BACK_PORCH;
				shift=1;
			end else begin
				next_state = RX;				
			end
			
		end

		default: begin
			if(half_baud)begin
				//rx_rdy = 1;
			end else begin
				next_state = BACK_PORCH;
			end
			
		end
	endcase
end

assign half_baud = (baudCounter == 12'h516) ? 1 : 0; 

assign full_baud = (baudCounter == 12'hA2C) ? 1 : 0; 

assign shift_reg_full = (cnt == 3'h7) ? 1 : 0;

assign rx_rdy = ((state == BACK_PORCH) && half_baud) ? 1 : 0;

endmodule


