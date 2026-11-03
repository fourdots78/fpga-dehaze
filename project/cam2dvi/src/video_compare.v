`default_nettype none
// Double-buffered, frame-coherent 320x144 pair, scaled to two 640x360 views.
// Preview sampling is 4x5; dehaze processing itself remains full 1280x720.
// Both views come from exactly the same completed source frame; never a wipe.
module video_compare #(
 parameter integer WIDTH=1280, HEIGHT=720,
 parameter integer VIEW_Y=176
)(
 input wire clk,rst_n,de_in,hs_in,vs_in,
 input wire [23:0] raw_in, enhanced_in,
 input wire [15:0] probe_addr, input wire probe_en,
 output wire [15:0] probe_data,
 output wire [15:0] probe_data_enh,
 output reg frame_done /* synthesis syn_maxfan=16 */, output reg frame_valid,
 output wire sample_en, output wire [8:0] sample_x, output wire [7:0] sample_y,
 input wire capture_trigger,manual_trigger,clear_snapshot,
 output reg snapshot_manual,
 input wire [2:0] capture_class,
 input wire box_valid,input wire [8:0] box_x,input wire [7:0] box_y,
 input wire [9:0] box_w,input wire [8:0] box_h,
 output reg snapshot_valid, output reg [7:0] capture_count,
 output reg [2:0] snapshot_class,
 input wire display_mode,
 output reg de_out,hs_out,vs_out, output reg [23:0] rgb_out
);
localparam integer SW=WIDTH/4, SH=(HEIGHT+4)/5, PIXELS=SW*SH;
reg [15:0] bank0[0:PIXELS-1],bank1[0:PIXELS-1];
reg [15:0] delta0[0:PIXELS-1],delta1[0:PIXELS-1];
reg [15:0] snapshot[0:(WIDTH/8)*(HEIGHT/8)-1];
reg [10:0] x;reg [9:0] y;reg pd,pv;
reg [9:0] complete_lines;
reg malformed_frame;
reg wr_bank,rd_bank;
reg [15:0] wr_addr /* synthesis syn_maxfan=16 */;
wire frame_edge=vs_in&&!pv;
assign sample_en=de_in && x<WIDTH && complete_lines<HEIGHT && wr_addr<PIXELS && x[1:0]==0 && (y%5)==0;
assign sample_x=x[10:2];assign sample_y=y/5;
wire [15:0] raw565={raw_in[23:19],raw_in[15:10],raw_in[7:3]};
// The current enhancer adds the same bounded delta to all RGB channels.
// Recover it from an unclipped channel; all-black/all-white cases saturate.
reg signed [8:0] delta_in;
always @(*)begin
 if(enhanced_in[15:8]!=0 && enhanced_in[15:8]!=255)
  delta_in=$signed({1'b0,enhanced_in[15:8]})-$signed({1'b0,raw_in[15:8]});
 else if(enhanced_in[23:16]!=0 && enhanced_in[23:16]!=255)
  delta_in=$signed({1'b0,enhanced_in[23:16]})-$signed({1'b0,raw_in[23:16]});
 else if(enhanced_in[7:0]!=0 && enhanced_in[7:0]!=255)
  delta_in=$signed({1'b0,enhanced_in[7:0]})-$signed({1'b0,raw_in[7:0]});
 else if(enhanced_in==24'h000000)delta_in=-31;
 else if(enhanced_in==24'hffffff)delta_in=31;
 else delta_in=0; // Mixed 0/255 primary colors are unchanged, not all clipped.
end
reg [15:0] write_addr0 /* synthesis syn_preserve=1 syn_maxfan=16 */;
reg [15:0] write_addr1 /* synthesis syn_preserve=1 syn_maxfan=16 */;
reg [15:0] write_rgb;reg [15:0] write_delta;reg we0,we1;
always @(posedge clk or negedge rst_n)begin
 if(!rst_n)begin write_addr0<=0;write_addr1<=0;write_rgb<=0;write_delta<=0;we0<=0;we1<=0;end
 else begin
  // V6 stores actual recovered RGB565, not a shared luminance offset.
  write_addr0<=wr_addr;write_addr1<=wr_addr;write_rgb<=raw565;
  write_delta<={enhanced_in[23:19],enhanced_in[15:10],enhanced_in[7:3]};
  we0<=sample_en&&!wr_bank;we1<=sample_en&&wr_bank;
 end
end
always @(posedge clk)begin
 if(we0)begin bank0[write_addr0]<=write_rgb;delta0[write_addr0]<=write_delta;end
 if(we1)begin bank1[write_addr1]<=write_rgb;delta1[write_addr1]<=write_delta;end
end
always @(posedge clk or negedge rst_n) begin
 if(!rst_n) begin
  x<=0;y<=0;pd<=0;pv<=0;wr_addr<=0;wr_bank<=0;rd_bank<=1;
  complete_lines<=0;malformed_frame<=0;
  frame_done<=0;frame_valid<=0;
 end else begin
  pd<=de_in;pv<=vs_in;frame_done<=0;
  if(frame_edge) begin
   x<=0;y<=0;wr_addr<=0;complete_lines<=0;malformed_frame<=0;
   if(wr_addr==PIXELS && complete_lines==HEIGHT && !malformed_frame && !de_in && !pd) begin
    rd_bank<=wr_bank;wr_bank<=~wr_bank;frame_valid<=1;frame_done<=1;
   end
  end else begin
   if(de_in) x<=x+1'b1;else x<=0;
   if(pd&&!de_in && y<HEIGHT-1) y<=y+1'b1;
   if(de_in && (x>=WIDTH || complete_lines>=HEIGHT))malformed_frame<=1;
   if(pd&&!de_in)begin
    if(x!=WIDTH)malformed_frame<=1;
    if(complete_lines<HEIGHT+1)complete_lines<=complete_lines+1'b1;
   end
   if(sample_en) wr_addr<=wr_addr+1'b1;
  end
 end
end
wire inside_view=de_in && y>=VIEW_Y && y<VIEW_Y+HEIGHT/2;
wire [10:0] local_x=(x>=WIDTH/2)?x-WIDTH/2:x;
wire [9:0] local_y=y-VIEW_Y;
// Increment floor(local_y*2/5)*SW only at line boundaries. No pixel-path divide.
reg [15:0] display_row_base;
reg [2:0] display_phase;
always @(posedge clk or negedge rst_n)begin
 if(!rst_n)begin display_row_base<=0;display_phase<=0;end
 else if(frame_edge)begin display_row_base<=0;display_phase<=0;end
 else if(pd&&!de_in)begin
  if(y<VIEW_Y)begin display_row_base<=0;display_phase<=0;end
  else if(y<VIEW_Y+HEIGHT/2)begin
   if(display_phase>=3)begin display_phase<=display_phase-3'd3;display_row_base<=display_row_base+SW;end
   else display_phase<=display_phase+3'd2;
  end
 end
end
wire [15:0] display_addr=display_row_base+(local_x>>1);
wire thumb=de_in && x>=24 && x<24+WIDTH/8 && y>=560 && y<560+HEIGHT/8;
wire [15:0] snap_addr=(y-10'd560)*(WIDTH/8)+(x-11'd24);
reg copying,manual_pending,pending_manual,auto_armed;
reg [2:0] cleared_class;
reg [15:0] blank_age;
always @(posedge clk or negedge rst_n)begin
 if(!rst_n)blank_age<=65535;
 else if(frame_done)blank_age<=0;
 else if(blank_age!=65535)blank_age<=blank_age+1'b1;
end
wire manual_slot=(blank_age==24004)&&!frame_done&&!frame_edge;
reg [2:0] pending_class;
reg [13:0] copy_index;
reg [7:0] copy_x;reg [6:0] copy_y;
wire [15:0] copy_addr=((copy_y*8)/5)*SW+copy_x*2;
reg [15:0] display_addr_d,snap_addr_d,read_addr_r,snap_addr_r;
always @(posedge clk)begin
 display_addr_d<=inside_view?display_addr:16'd0;
 snap_addr_d<=thumb?snap_addr:16'd0;
 read_addr_r<=(copying&&!de_in)?((copy_index<(WIDTH/8)*(HEIGHT/8))?copy_addr:16'd0):
  (probe_en&&!de_in)?probe_addr:display_addr_d;
 snap_addr_r<=snap_addr_d;
end
reg [15:0] q0,q1;reg [15:0] dq0,dq1;reg [15:0] sq;
always @(posedge clk) begin
 q0<=bank0[read_addr_r];q1<=bank1[read_addr_r];
 dq0<=delta0[read_addr_r];dq1<=delta1[read_addr_r];
 sq<=snapshot[snap_addr_r];
end
reg [15:0] probe_data_r /* synthesis syn_preserve=1 */;
// Classification uses the enhanced frame; evidence snapshots retain the raw frame.
// Classification and snapshots use the raw completed frame. Enhancement
// tuning cannot alter the detector's pixel samples or template threshold.
always @(posedge clk)probe_data_r<=rd_bank?q1:q0;
assign probe_data=probe_data_r;
// Same address, same latency, but from the enhanced (delta) buffer.
reg [15:0] probe_data_enh_r /* synthesis syn_preserve=1 */;
always @(posedge clk)probe_data_enh_r<=rd_bank?dq1:dq0;
assign probe_data_enh=probe_data_enh_r;
// Copy the actual recognized, completed frame during vertical blanking.
// One read per cycle plus the synchronous-RAM pipeline; never next-frame capture.
always @(posedge clk) if(rst_n && copying && !clear_snapshot && !de_in && copy_index>=3)
 snapshot[copy_index-2'd3]<=probe_data;
always @(posedge clk or negedge rst_n) begin
 if(!rst_n)begin copying<=0;copy_index<=0;copy_x<=0;copy_y<=0;snapshot_valid<=0;capture_count<=0;
  snapshot_class<=0;pending_class<=0;snapshot_manual<=0;pending_manual<=0;manual_pending<=0;auto_armed<=1;cleared_class<=0;end
 else begin
  if(manual_trigger)manual_pending<=1;
  if(capture_class==0||capture_class!=cleared_class)auto_armed<=1;
  if(frame_valid && !copying && !de_in &&
     ((capture_trigger&&auto_armed)||(manual_pending&&manual_slot)))begin
   copying<=1;copy_index<=0;copy_x<=0;copy_y<=0;snapshot_valid<=0;
   // A manual image is never advertised as a confirmed classification.
   pending_manual<=!(capture_trigger&&auto_armed);
   pending_class<=(capture_trigger&&auto_armed)?capture_class:3'd0;
   manual_pending<=0;
  end
  if(copying)begin
   if(de_in)begin copying<=0;snapshot_valid<=0;end
   else if(copy_index==(WIDTH/8)*(HEIGHT/8)+2)begin
    copying<=0;snapshot_valid<=1;capture_count<=(capture_count==255)?8'd255:capture_count+1'b1;snapshot_class<=pending_class;snapshot_manual<=pending_manual;
   end else begin
    copy_index<=copy_index+1'b1;
    if(copy_index<(WIDTH/8)*(HEIGHT/8))begin
     if(copy_x==WIDTH/8-1)begin copy_x<=0;copy_y<=copy_y+1'b1;end
     else copy_x<=copy_x+1'b1;
    end
   end
  end
  if(clear_snapshot)begin
   copying<=0;manual_pending<=0;snapshot_valid<=0;capture_count<=0;
   snapshot_class<=0;snapshot_manual<=0;auto_armed<=0;cleared_class<=capture_class;
  end
 end
end
reg [10:0] box_start_x,box_end_x,box_start_y,box_end_y;
always @(posedge clk)begin
 box_start_x<={box_x,1'b0};box_end_x<=({1'b0,box_x}+box_w)*2;
 box_start_y<=VIEW_Y+(({1'b0,box_y}*5+1)>>1);
 box_end_y<=VIEW_Y+((({1'b0,box_y}+box_h)*5+1)>>1);
end
wire box_border=box_valid&&inside_view&&x>=WIDTH/2&&
 local_x>=box_start_x&&local_x<box_end_x&&y>=box_start_y&&y<box_end_y&&
 (local_x<box_start_x+2||local_x+2>=box_end_x||y<box_start_y+2||y+2>=box_end_y);
// ---- display mode decode ----
// 0=raw+box  1=dehaze+box
wire show_proc=display_mode;   // 1=dehaze, 0=raw
wire show_box =1'b1;           // both modes draw the box
reg bank_d,view_d,right_d,thumb_d,valid_d,snap_d,divider_d,box_d;
reg de_d,hs_d,vs_d;
reg [10:0] meta_q1,meta_q2,meta_q3;
wire [10:0] meta_d={box_d,bank_d,view_d,right_d,thumb_d,valid_d,snap_d,divider_d,de_d,hs_d,vs_d};
wire bank_q,view_q,right_q,thumb_q,valid_q,snap_q,divider_q,de_q,hs_q,vs_q,box_q;
assign {box_q,bank_q,view_q,right_q,thumb_q,valid_q,snap_q,divider_q,de_q,hs_q,vs_q}=meta_q3;
reg [15:0] selected565 /* synthesis syn_preserve=1 */;
reg [15:0] dq /* synthesis syn_preserve=1 */;
always @(posedge clk)begin
 selected565<=(meta_q2[6]&&meta_q2[4])?sq:(meta_q2[9]?q1:q0);
 dq<=meta_q2[9]?dq1:dq0;
end
wire [23:0] expanded={selected565[15:11],selected565[15:13],selected565[10:5],selected565[10:9],selected565[4:0],selected565[4:2]};
function [7:0] add_sat;input [7:0] value;input signed [7:0] change;reg signed [9:0] sum;begin
 sum=$signed({1'b0,value})+change;
 if(sum<0)add_sat=0;else if(sum>255)add_sat=255;else add_sat=sum[7:0];
end endfunction
always @(posedge clk or negedge rst_n) begin
 if(!rst_n) begin
  bank_d<=0;view_d<=0;right_d<=0;thumb_d<=0;valid_d<=0;snap_d<=0;divider_d<=0;box_d<=0;
  de_d<=0;hs_d<=0;vs_d<=0;de_out<=0;hs_out<=0;vs_out<=0;rgb_out<=0;
  meta_q1<=0;meta_q2<=0;meta_q3<=0;
 end else begin
  bank_d<=rd_bank;view_d<=inside_view;right_d<=x>=WIDTH/2;thumb_d<=thumb;box_d<=box_border;
  valid_d<=frame_valid;snap_d<=snapshot_valid;divider_d<=de_in&&x==WIDTH/2;
  de_d<=de_in;hs_d<=hs_in;vs_d<=vs_in;
  meta_q1<=meta_d;meta_q2<=meta_q1;meta_q3<=meta_q2;
  de_out<=de_q;hs_out<=hs_q;vs_out<=vs_q;
  if(divider_q) rgb_out<=24'hffffff;
  else if(box_q&&valid_q&&show_box)rgb_out<=24'h40ff60;
  else if(view_q&&valid_q&&right_q)
   rgb_out<=show_proc?{dq[15:11],dq[15:13],dq[10:5],dq[10:9],dq[4:0],dq[4:2]}:expanded;
  else if((view_q&&valid_q)||(thumb_q&&snap_q))rgb_out<=expanded;
  else rgb_out<=24'h182028;
 end
end
endmodule
`default_nettype wire
