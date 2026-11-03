module cmos_8_16bit(
	input              rst,
	input              pclk,
	input [7:0]        pdata_i,
	input              de_i,
	output reg[15:0]   pdata_o,
	output reg	       hblank,
	output reg         de_o
);

	reg[7:0] pdata_i_d0;
	reg x_cnt;
	reg de_d1;
	always@(posedge pclk or posedge rst)	//Latch
	begin
		if(rst) pdata_i_d0 <= 0; else pdata_i_d0 <= pdata_i;
	end

	always@(posedge pclk or posedge rst)
	begin
		if(rst) x_cnt <= 0;
		else if(de_i & !de_d1)
			x_cnt <= 1;
		else
			x_cnt <= ~x_cnt ;

	end

	always@(posedge pclk or posedge rst)
	begin
		if(rst)
			de_o <= 1'b0;
		else if(de_i && !de_d1)
			de_o <= 1'b0; // First byte never produces a pixel clock edge.
		else if(x_cnt)
			de_o <= 1'b1;
		else
			de_o <= 1'b0;
	end

	always@(posedge pclk or posedge rst)begin
		if(rst)begin de_d1<=0;hblank<=0;end else begin
		de_d1 <= de_i;
		//de_d2 <= de_d1;
	 	hblank <= de_d1;
		end
	end 


	always@(posedge pclk or posedge rst)
	begin
		if(rst)
			pdata_o <= 16'd0;
		else if(de_i && x_cnt)
			pdata_o <= {pdata_i_d0,pdata_i};
		else
			pdata_o <= pdata_o;
	end

endmodule 
