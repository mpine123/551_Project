module snn_core_tb();

reg start;
reg rst_n;
reg clk;
wire q_input; 
wire [9:0] addr_input_unit; 
wire [3:0] digit;
wire done;
reg we, data;

ram #(.DATA_WIDTH(1), .ADDR_WIDTH(10), .INIT_FILE("ram_input_contents_sample_8.txt")) inputValuesDUT(.q(q_input),.clk(clk),.we(we),.data(data),.addr(addr_input_unit));


//RAM_INPUT_UNIT ram(.q(q_input),.clk(clk),.we(we),.data(data),.addr(addr_input_unit));
snn_core coreDUT(.start(start),.rst_n(rst_n),.clk(clk),.q_input(q_input),.addr_input_unit(addr_input_unit),.digit(digit),.done(done));


initial clk =0;
always #5 clk = ~clk;

initial begin
	rst_n = 0;
	start= 0;
	we = 0;
	data = 0;
	@(posedge clk);
	
	rst_n = 1;
	@(posedge clk);
	start = 1;
	@(posedge clk);
	start = 0;

	@(posedge done);
	@(posedge clk);
	$display("Expected: 0 got: %d: TIME: %d\n", digit, $time);
	$stop;
end


endmodule
