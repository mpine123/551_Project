module mac_tb();

logic[7:0]a;
logic[7:0]b;
logic clr_n, clk, rst_n;

logic[25:0] acc;

mac iMac(.a(a),.b(b),.clr_n(clr_n),.clk(clk),.rst_n(rst_n), .acc(acc));





initial begin
clk = 0;
clr_n = 0;
rst_n = 0;

@(posedge clk);
@(negedge clk);
rst_n = 1;
clr_n = 1;
a = 2;
b = 5;
@(negedge clk);
a = -2;
b = 5;
@(negedge clk);
a = -3;
b = 8;
#15;
clk = 0;
clr_n = 0;
rst_n = 0;
@(posedge clk);
@(negedge clk);
rst_n = 1;
clr_n = 1;
a = 126;
b = 126;
@(negedge clk);
a = 126;
b = 126;
@(negedge clk);
a = 126;
b = 126;
#15;
clk = 0;
clr_n = 0;
rst_n = 0;
@(posedge clk);
@(negedge clk);
rst_n = 1;
clr_n = 1;
a = 8'h80;
b = 8'h7F;
@(negedge clk);
a = 8'h80;
b = 8'h7F;
@(negedge clk);
a = 8'h80;
b = 8'h7F;
#15;
$stop;


end


always #5 clk = ~clk;

endmodule

