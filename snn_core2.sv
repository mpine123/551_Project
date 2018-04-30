module snn_core(start,rst_n,clk,q_input,addr_input_unit,digit,done);
input start,q_input,rst_n,clk;
output logic [9:0]addr_input_unit; //also used for counting
output logic[3:0] digit;
output done;
typedef enum reg [3:0] {IDLE,MAC_HIDDEN,MAC_HIDDEN_BP1,MAC_HIDDEN_BP2,MAC_HIDDEN_WRITE,MAC_OUTPUT,MAC_OUTPUT_BP1_MAC_OUTPUT_BP2_MAC_OUTPUT_WRITE,DONE}state_t;
state_t state,next_state;
logic[7:0] q_input_sign_extended; //sign extend q input for MAC's use

logic [5:0] hidden_layer_counter; //counts the 32 layers
logic hidden_count_inc;
logic in_count_clr; //clears the address counter

logic hidden_count_clr; //clears counter for hidden layer (32)
logic mac_clr; // clear signal for the MAC 
logic[7:0] input_val,weight; //inputs to the MAC
logic[25:0] acc; //output of MAC
logic layer_select,hidden_WE; //write enables to trigger when RAMS should be updated
logic [7:0]romHiddenWeight,romOutputWeight,ramHiddenOutput, LUT_output;
logic [10:0] LUT_addr; //input to activation function (rectified MAC result)
logic [14:0] addr_hidden_weight; // address to hidden ROM unit: {cnt_hidden[4:0],cnt_input[9:0]}
logic [8:0] addr_output_weight;  // address to output ROM unit: {cnt_output[3:0],cnt_hidden{4:0]}
logic [3:0] digit_count; //used for keeping track of which digit we are assessing
logic digit_clr;
logic output_count_incr;// increment digit count
logic in_rdy, hidden_rdy; //when the last input/hiden value has been loaded 
logic hidden_done, out_done; //When all nodes in layer are calculated and saved

ROM_ACT_FUNC_LUT_VALUES Activation_Function(.addr(LUT_addr),.clk(clk),.q(LUT_output));
ROM_HIDDEN_LAYER Hidden_Layer_Weights(.addr(addr_hidden_weight),.clk(clk),.q(romHiddenWeight));
ROM_OUTPUT_LAYER Output_Layer_Weights(.addr(addr_output_weight),.clk(clk),.q(romOutputWeight));

//RAM_INPUT_LAYER input_layer(.addr(addr_input_unit),.data(),.we(),.clk(clk),.q(q));
RAM_HIDDEN_OUTPUT_VALUES hidden_layer(.addr(hidden_layer_counter),.data(LUT_output),.we(hidden_WE),.clk(clk),.q(ramHiddenOutput));

//GO BACK TO MAC RESULT RECTIFICATION (rect(mac)+1024)
mac MAC (.a(input_val),.b(weight),.clr_n(mac_clr),.rst_n(rst_n),.clk(clk),acc(acc));





//state machine always block
always @(posedge clk, negedge rst_n) begin

	if(!rst_n) begin
		state <= IDLE;
	end else begin
		state <= next_state;
	end
end

//ADDR input FF
always @(posedge clk, negedge rst_n) begin

	if(!rst_n)begin
		addr_input_unit <= 10'h000;
	end else if(in_count_clr)begin
		addr_input_unit <= 10'h000;
	end else begin
		addr_input_unit <= addr_input_unit + 1;
	end

end


//Hidden layer counter FF
always @(posedge clk, negedge rst_n) begin

	if(!rst_n)begin
		hidden_layer_counter <= 6'h00;
	end else if(hidden_count_clr)begin
		hidden_layer_counter <= 6'h00;
	end else if(hidden_count_inc)begin
		hidden_layer_counter <= hidden_layer_counter + 1;
	end else begin
		hidden_layer_counter <= hidden_layer_counter;
	end

end

//Rectifier
always_comb begin
	if(acc[25] == 0 && ((acc >> 17) & 8'hFF) != 8'h00)begin
		LUT_addr = 11'h3FF;
	end else if(acc[25] == 1 && ((acc >>17) & 8'hFF) != 8h'FF)begin
		LUT_addr = 11'h400;
	end else begin
		LUT_addr = acc[17:7];
	end
	
	//NOT SURE SEE SLIDE 14
	LUT_addr = LUT_addr + 11'h200;
	
end

//FSM
always_comb begin

in_count_clr = 0;
hidden_count_clr = 0;
hidden_count_inc = 0;
layer_select = 0;
hidden_WE=0;
we_output_layer=0; 
mac_clr = 0;
digit_clr = 0;
output_count_incr = 0;

case(state)
		IDLE: begin
		in_count_clr = 1;
		hidden_count_clr = 1;
		mac_clr = 1;
		digit_clr = 1;

			if(!start) next_state = IDLE;
			else next_state = MAC_HIDDEN;
		end

		MAC_HIDDEN: begin
			//this is 784
			if(in_rdy) begin //TODO need logic for input ready
				next_state = MAC_HIDDEN_BP1;
				in_count_clr = 1;
			end else next_state = MAC_HIDDEN;
		end

		MAC_HIDDEN_BP1:begin
		//unconditional
		next_state = MAC_HIDDEN_BP2;
		end


		MAC_HIDDEN_BP2:begin
		//unconditional
		mac_clr = 1;
		next_state = MAC_HIDDEN_WRITE;
		end
		
		MAC_HIDDEN_WRITE:begin
		hidden_WE=1;
		if(hidden_done) begin 
			next_state=MAC_OUTPUT;
			layer_select = 1;
			hidden_count_clr = 1;
		end else begin
			next_state = MAC_HIDDEN;
			hidden_count_inc = 1;
			end
		end
		
		MAC_OUTPUT: begin
		layer_select = 1;
		if(hidden_rdy) begin
			next_state = MAC_OUTPUT_BP1;
			hidden_count_clr = 1;
		end else next_state=MAC_OUTPUT;
		end
		
		MAC_OUTPUT_BP1: begin
		layer_select = 1;
		next_state=MAC_OUTPUT_BP2;
		end
		
		MAC_OUTPUT_BP2: begin
		layer_select = 1;
		mac_clr = 1;
		next_state=MAC_OUTPUT_WRITE;
		end

		MAC_OUTPUT_WRITE: begin
		if(out_done)begin
			next_state = DONE;
			done = 1;
		end else begin
			layer_select = 1;
			output_count_incr = 1;
		end
		end

		DONE: begin
		next_state=IDLE;
		end

		default: begin 
			next_state = IDLE;
		end
	
	endcase

end

assign hidden_rdy = (hidden_layer_counter == 6'h20);//32 // maybe use a ?
assign in_rdy = (addr_input_unit == 10'h310); //784
assign hidden_done = hidden_rdy; // a bit sketch /////////////////////////////
assign out_done = (digit_count == 4'hA);


assign q_input_sign_extended= {0,{7{q_input}}};
assign input_val = (layer_select) ? ramHiddenOutput : q_input_sign_extended;
assign weight = (layer_select) ? romHiddenWeight : romOutputWeight;
assign addr_hidden_weight={cnt_hidden[4:0],addr_input_unit};
assign addr_output_weight={digit_count,cnt_hidden[4:0]};
endmodule
