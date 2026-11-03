`timescale 1ns/1ps
module tb_controls;
reg clk=0;always #5 clk=~clk;reg rst=0,key=1;wire mode,cap,clear;
integer nc=0,nl=0;
demo_controls #(.DEBOUNCE(4),.DOUBLE_GAP(30),.LONG_HOLD(60)) d(clk,rst,key,mode,cap,clear);
always @(posedge clk)begin if(cap)nc=nc+1;if(clear)nl=nl+1;end
task waitn;input integer n;begin repeat(n)@(negedge clk);end endtask
task press;input integer n;begin key=0;waitn(n);key=1;waitn(10);end endtask
initial begin waitn(4);rst=1;waitn(5);
 key=0;waitn(2);key=1;waitn(50);if(mode!=1||nc||nl)$fatal(1,"bounce");
 press(15);waitn(35);if(mode!=0||nc||nl)$fatal(1,"single click");
 press(15);press(15);waitn(35);if(mode!=0||nc!=1||nl)$fatal(1,"double click");
 press(120);waitn(35);if(mode!=0||nc!=1||nl!=1)$fatal(1,"long press");
 press(15);waitn(35);if(mode!=1||nc!=1||nl!=1)$fatal(1,"release after long");
 $display("PASS button debounce, single/double click, held clear once and no release side effect");$finish;end
endmodule
