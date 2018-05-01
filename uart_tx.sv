///////////////////////////////////////////////////////////////////////////////
//                   
// Title:             uart_tx
// Semester:          ECE 551 Spring 2018
//
// Authors:           Lorne Miller, Devin Ott, Maddie Pine, Carter Swedal
// Lecturer's Name:   Younghyun Kim
// Group Number:      1
//
//////////////////////////////////////////////////////////////////////////////

module uart_tx(clk,rst_n, tx_start, tx_data,tx,tx_rdy);

input clk,rst_n,tx_start;
input reg[7:0] tx_data;
output tx;
output reg tx_rdy;

typedef enum reg {IDLE,TX}state_t;
state_t state,next_state;

reg [9:0] shift_reg;
reg [3:0] shift_index_counter;
reg[11:0]baud_count;

logic[9:0]next_shift_reg;
logic[9:0]ld_shift_reg;
logic bit_full,baud_full,shift,load,clr;

//state reg's always block
always_ff @(posedge clk, negedge rst_n) begin

	if(!rst_n)begin
		state <= IDLE;
	end else begin
		state <= next_state;
	end

end

//shift_reg's always block
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n) shift_reg <= 10'h3FF;
	else if(load) begin 
		shift_reg<=ld_shift_reg;
	end
	else if(baud_full) shift_reg <= next_shift_reg;
	else 
		shift_reg <= shift_reg;

end


////tx_data reg's always block
//always_ff @(posedge clk, negedge rst_n) begin
//	if(!rst_n || clr_shift_reg)begin
//		tx_data <= 8'h00;
//	end else begin
//		if(shift)beg+in
//			tx_data <= tx_data>>1;
//		end else begin
//			tx_data <= rx_data;
//		end
//	end
//
//end

//baudCounter reg's always block
always_ff @(posedge clk, negedge rst_n) begin
	if(~rst_n)begin
		baud_count <= 12'h000;
	end 
	else if(clr) baud_count <= 12'h000;
	else begin
		baud_count <= baud_count + 1;
	end

end

//cnt reg's always block
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n) begin
		shift_index_counter <= 4'h0;
	end
	else if(state == IDLE) shift_index_counter<=4'h0;
	 else begin 
		if(shift)begin
			shift_index_counter <= shift_index_counter + 1;
		end else begin
			shift_index_counter <= shift_index_counter;	
		end
	end

end

always_comb begin
shift=0;
load=0;
clr=0;
tx_rdy=0;
next_state=IDLE;

	case(state)
		IDLE: begin
			if(tx_start)begin
				load=1;
				clr=1;
				next_state=TX;
			end
			else begin
				clr=1;
				tx_rdy=1;	
			end
		end
		TX: begin
			if(bit_full) begin
				next_state=IDLE;
			end
	
			else begin
				if(baud_full) begin
					shift=1;
					clr=1;
					next_state=TX;
				end
				else begin
					next_state=TX;
				end
			end
		end
		default: begin 
			next_state=IDLE;
		end
	
	endcase
end
assign bit_full = (shift_index_counter == 4'hA) ? 1:0;
assign baud_full = (baud_count == 12'hA2C)? 1:0;
assign tx=shift_reg[0];
assign next_shift_reg={1'b1,{shift_reg[9:1]}};
assign ld_shift_reg={1'b1,tx_data,1'b0};
//assign next_shift_reg={{1{1}},tx_data,{1{0}}};

endmodule 