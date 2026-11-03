`timescale 1ns/1ps
module tb_capture;
reg clk=0;always #5 clk=~clk;
reg rst=0,de=0,vs=0,manual=0,clear=0,auto_cap=0;reg[2:0]cid=2;
reg[23:0]rgb=24'h808080;wire valid,sman,fd,fv;wire[7:0]count;wire[2:0]saved;
integer x,y,i;
video_compare #(.WIDTH(32),.HEIGHT(40)) d(.clk(clk),.rst_n(rst),.de_in(de),.hs_in(1'b0),.vs_in(vs),.raw_in(rgb),.enhanced_in(rgb),.probe_addr(16'd0),.probe_en(1'b0),.probe_data(),.probe_data_enh(),.frame_done(fd),.frame_valid(fv),.sample_en(),.sample_x(),.sample_y(),.capture_trigger(auto_cap),.manual_trigger(manual),.clear_snapshot(clear),.snapshot_manual(sman),.capture_class(cid),.box_valid(1'b0),.box_x(9'd0),.box_y(8'd0),.box_w(10'd0),.box_h(9'd0),.snapshot_valid(valid),.capture_count(count),.snapshot_class(saved),.display_mode(1'b1),.de_out(),.hs_out(),.vs_out(),.rgb_out());
task waitn;input integer n;begin repeat(n)@(negedge clk);end endtask
task frame;begin vs=1;waitn(10);vs=0;
for(y=0;y<40;y=y+1)begin for(x=0;x<32;x=x+1)begin de=1;waitn(1);end de=0;waitn(5);end waitn(10);end endtask
initial begin waitn(4);rst=1;frame;
 manual=1;waitn(1);manual=0;vs=1;waitn(25000);vs=0;
 if(!valid||!sman||count!=1||saved!=0)$fatal(1,"manual queue/copy metadata");
 for(i=0;i<20;i=i+1)if(d.snapshot[i]!==16'h8410)$fatal(1,"manual snapshot content %d %h",i,d.snapshot[i]);
 clear=1;auto_cap=1;waitn(1);clear=0;auto_cap=0;waitn(5);
 if(valid||count||saved||sman)$fatal(1,"clear priority");
 auto_cap=1;waitn(1);auto_cap=0;waitn(50);if(valid)$fatal(1,"same class immediately recaptured");
 cid=0;waitn(2);cid=4;auto_cap=1;waitn(1);auto_cap=0;waitn(50);
 if(!valid||sman||saved!=4||count!=1)$fatal(1,"auto rearm metadata");
 $display("PASS queued manual raw snapshot, unconfirmed label, clear priority, auto rearm and exact content");$finish;end
endmodule
