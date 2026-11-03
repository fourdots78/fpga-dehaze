`timescale 1ns/1ps
module tb_sign_v12;
reg clk=0;always #5 clk=~clk;
reg rst=0,fd=0,se=0,active=0;reg [8:0] x=0;reg [7:0] y=0;reg [23:0] rgb=0;
wire pe,trig,candidate,bv;wire [15:0] addr;reg [15:0] data;
wire [2:0] cid,last;wire [7:0] distance,by;wire [8:0] bx,bh;wire [9:0] bw;
reg [15:0] memory[0:46079];reg [23:0] color_memory[0:46079];reg [15:0] a1,a2;
sign_detector dut(.clk(clk),.rst_n(rst),.frame_done(fd),.sample_en(se),.sample_x(x),.sample_y(y),.sample_rgb(rgb),.video_active(active),
 .probe_en(pe),.probe_addr(addr),.probe_data(data),.current_class(cid),.last_class(last),.capture_trigger(trig),
 .match_distance(distance),.candidate_valid(candidate),.box_valid(bv),.box_x(bx),.box_y(by),.box_w(bw),.box_h(bh),.dbg_score(),.roi_valid(),.roi_x(),.roi_y(),.roi_w(),.roi_h(),.debug_patch(),.debug_valid(),.debug_distance());
always @(posedge clk)begin a1<=addr;a2<=a1;if(a2<46080)data<=memory[a2];else data<=16'hxxxx;end
integer i,f,expected,errors=0,triggers=0,max_age=0;
reg [256*8-1:0] name,path;
always @(posedge clk)if(rst)begin
 if(trig)triggers=triggers+1;
 if(cid==1||last==1)$fatal(1,"Disabled construction class emitted");
 if(dut.age>max_age)max_age=dut.age;
 if(pe&&(se||active))$fatal(1,"RAM probe during active video");
 if(pe&&addr>=46080)$fatal(1,"Probe address outside 320x144: %0d",addr);
end
task reset_case;begin rst=0;se=0;fd=0;active=0;repeat(4)@(negedge clk);rst=1;triggers=0;max_age=0;end endtask
task send_frame;begin
 for(i=0;i<46080;i=i+1)begin
  @(negedge clk);se=1;active=1;x=i%320;y=i/320;
  rgb=color_memory[i];
  @(negedge clk);se=0;active=0;repeat(2)@(negedge clk);
 end
 @(negedge clk);fd=1;@(negedge clk);fd=0;
 repeat(26000)@(negedge clk);
 if(dut.state!=0)$fatal(1,"Detector exceeded budget");
end endtask
task run_case;input [256*8-1:0] case_name;input integer want;begin
 name=case_name;reset_case;$sformat(path,"sim/%0s.hex",name);$readmemh(path,memory);$sformat(path,"sim/%0s_rgb.hex",name);$readmemh(path,color_memory);
 for(f=0;f<3;f=f+1)send_frame;
 if(cid!==want||triggers!=(want==0?0:1)||(want!=0&&(last!==want||!bv||bw<16||bh<12||bx+bw>320||by+bh>144)))begin
  errors=errors+1;$display("FAIL %0s class=%0d expected=%0d distance=%0d captures=%0d age=%0d box=%d,%d,%d,%d",name,cid,want,distance,triggers,max_age,bx,by,bw,bh);
 end else $display("PASS %0s class=%0d distance=%0d captures=%0d age=%0d box=%d,%d,%d,%d",name,cid,distance,triggers,max_age,bx,by,bw,bh);
end endtask
initial begin
 `include "sim/cases.vh"
 if(errors)$fatal(1,"FAIL detector cases=%0d",errors);
 $display("PASS detector calibration and independent reference regressions");$finish;
end
initial begin #2000000000;$fatal(1,"timeout");end
endmodule
