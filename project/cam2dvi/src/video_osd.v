`default_nettype none
// Native pixel-domain Chinese OSD. RGB and all timing signals gain four cycles.
module video_osd #(parameter integer SHOW_DEBUG_PATCH=0)(
 input wire clk, rst_n, de_in, hs_in, vs_in,
 input wire [7:0] r_in, g_in, b_in,
 input wire [2:0] sign_id,saved_id,
 input wire snapshot_valid,candidate,
 input wire display_mode,snapshot_manual,source_ready,
 input wire [7:0] capture_count,
 input wire [7:0] dbg_score,
 input wire [255:0] debug_patch,
 input wire debug_valid,
 output reg de_out, hs_out, vs_out,
 output reg [7:0] r_out, g_out, b_out
);
`include "T:/cam2dvi/src/osd_layout.vh"
reg [31:0] font_rom[0:4095] /* synthesis syn_romstyle="logic" */;
initial $readmemh("T:/cam2dvi/src/osd_font.hex", font_rom);
reg [10:0] x;
reg [9:0] y;
reg prev_de, prev_vs;
always @(posedge clk or negedge rst_n) begin
 if(!rst_n) begin x<=0; y<=0; prev_de<=0; prev_vs<=0; end
 else begin
  prev_de<=de_in; prev_vs<=vs_in;
  if(vs_in && !prev_vs) begin x<=0; y<=0; end
  else begin
   if(de_in) x<=x+1'b1; else x<=0;
   if(prev_de && !de_in && y<719) y<=y+1'b1;
  end
 end
end
reg [3:0] count_h,count_t,count_u;
always @(posedge clk)begin count_h<=capture_count/100;count_t<=(capture_count%100)/10;count_u<=capture_count%10;end
reg [6:0] glyph;

// score readout: split 0..99 into two digits (clamped at 99)
reg [3:0] score_tens, score_units;
always @(posedge clk) begin
 if(dbg_score>=8'd90) begin score_tens<=4'd9;
  score_units<=(dbg_score>8'd99)?4'd9:(dbg_score-8'd90); end
 else if(dbg_score>=8'd80) begin score_tens<=4'd8; score_units<=dbg_score-8'd80; end
 else if(dbg_score>=8'd70) begin score_tens<=4'd7; score_units<=dbg_score-8'd70; end
 else if(dbg_score>=8'd60) begin score_tens<=4'd6; score_units<=dbg_score-8'd60; end
 else if(dbg_score>=8'd50) begin score_tens<=4'd5; score_units<=dbg_score-8'd50; end
 else if(dbg_score>=8'd40) begin score_tens<=4'd4; score_units<=dbg_score-8'd40; end
 else if(dbg_score>=8'd30) begin score_tens<=4'd3; score_units<=dbg_score-8'd30; end
 else if(dbg_score>=8'd20) begin score_tens<=4'd2; score_units<=dbg_score-8'd20; end
 else if(dbg_score>=8'd10) begin score_tens<=4'd1; score_units<=dbg_score-8'd10; end
 else begin score_tens<=4'd0; score_units<=dbg_score; end
end
reg [4:0] row, col;
reg active;
reg [23:0] ink;
wire [10:0] tx = x-11'd24;
wire [10:0] rx = x-11'd664;
wire [10:0] ix = x-11'd208;
always @(*) begin
 glyph=0; row=0; col=0; active=0; ink=24'hf0f8ff;
 if(de_in) begin
  if(y>=8 && y<40 && x>=24 && x<24+32*TITLE_LENGTH) begin
   glyph=title_glyph(tx[10:5]);row=y-8;col=tx[4:0];active=1;
  end else if(y>=8 && y<40 && x>=664 && x<664+32*MODE_LENGTH) begin
   glyph=display_mode?mod1_glyph(rx[10:5]):mod0_glyph(rx[10:5]);row=y-8;col=rx[4:0];active=1;ink=24'h60ffa0;
  end else if(y>=8 && y<40 && x>=856 && x<984)begin
   glyph=source_ready?ready_glyph((x-856)>>5):waiting_glyph((x-856)>>5);
   row=y-8;col=(x-856)%32;active=1;ink=24'hffffff;
  end else if(y>=56 && y<88 && x>=24 && x<24+32*LEFT_LENGTH) begin
   glyph=left_glyph(tx[10:5]);row=y-56;col=tx[4:0];active=1;ink=24'h50e0ff;
  end else if(y>=56 && y<88 && x>=664 && x<664+32*RIGHT_LENGTH) begin
   glyph=display_mode?right_glyph(rx[10:5]):left_glyph(rx[10:5]);row=y-56;col=rx[4:0];active=1;ink=24'h60ffa0;
  end else if(y>=112 && y<144 && x>=24 && x<24+32*26) begin
   if(sign_id!=0)glyph=name_glyph(sign_id,tx[10:5]);
   else if(candidate)glyph=candidate_glyph(tx[10:5]);else glyph=scan_glyph(tx[10:5]);
   row=y-112;col=tx[4:0];active=1;ink=24'hffe070;
  end else if(y>=560 && y<592 && x>=208 && x<208+32*26)begin
   if(snapshot_valid)glyph=snapshot_manual?manual_glyph(ix[10:5]):name_glyph(saved_id,ix[10:5]);else glyph=empty_glyph(ix[10:5]);
   row=y-560;col=ix[4:0];active=1;ink=24'hffe070;
  end else if(y>=600 && y<632 && x>=208 && x<208+32*26)begin
   if(snapshot_valid&&!snapshot_manual)glyph=info_glyph(saved_id,ix[10:5]);
   row=y-600;col=ix[4:0];active=1;ink=24'hf0f8ff;
  end else if(y>=648 && y<680 && x>=24 && x<24+32*SNAP_LENGTH)begin
   glyph=snap_glyph(tx[10:5]);row=y-648;col=tx[4:0];active=1;ink=24'hf0f8ff;
  end else if(y>=648 && y<680 && x>=664 && x<856)begin
   if(x<728)glyph=counter_glyph((x-664)>>5);
   else if(x<760)glyph=0;
   else if(x<792)glyph=digit_glyph(count_h);
   else if(x<824)glyph=digit_glyph(count_t);
   else glyph=digit_glyph(count_u);
   row=y-648;col=(x-664)%32;active=1;ink=24'hf0f8ff;
  end else if(y>=680 && y<712 && x>=664 && x<1240)begin
   glyph=help_glyph((x-664)>>5);row=y-680;col=(x-664)%32;active=1;ink=24'h60ffa0;
  end else if(y>=680 && y<712 && x>=24 && x<24+32*FOOTER_LENGTH) begin
   glyph=footer_glyph(tx[10:5]);row=y-680;col=tx[4:0];active=1;ink=24'hffe070;
  end
 end
end
reg [31:0] font_row;
reg [6:0] glyph_g; reg [4:0] row_g,col_g;
reg active_g,dark_g,de_g,hs_g,vs_g;
reg [23:0] rgb_g,ink_g;
reg [11:0] font_addr_q;
reg [4:0] col_q;
reg active_q,dark_q,de_q,hs_q,vs_q;
reg [23:0] rgb_q,ink_q;
reg [4:0] col_d;
reg active_d, dark_d, de_d, hs_d, vs_d;
reg [23:0] rgb_d, ink_d;
// 16x16 native matcher input enlarged eightfold, lower-right unused area.
// Split row/column selection across existing pipeline stages.
wire [10:0] patch_x=x-11'd1104;
wire [9:0] patch_y=y-10'd544;
reg patch_g,patch_q,patch_d,patch_bit_d;
reg [3:0] patch_row_g,patch_col_g,patch_col_q;
reg [15:0] patch_row_q;
reg patch_valid_g,patch_valid_q,patch_valid_d;
always @(posedge clk or negedge rst_n) begin
 if(!rst_n) begin
  patch_g<=0;patch_q<=0;patch_d<=0;patch_bit_d<=0;
  patch_valid_g<=0;patch_valid_q<=0;patch_valid_d<=0;
  patch_row_g<=0;patch_col_g<=0;patch_col_q<=0;patch_row_q<=0;
  glyph_g<=0;row_g<=0;col_g<=0;active_g<=0;dark_g<=0;
  de_g<=0;hs_g<=0;vs_g<=0;rgb_g<=0;ink_g<=0;
  font_addr_q<=0;col_q<=0;active_q<=0;dark_q<=0;
  de_q<=0;hs_q<=0;vs_q<=0;rgb_q<=0;ink_q<=0;
  font_row<=0; col_d<=0; active_d<=0; dark_d<=0;
  de_d<=0;hs_d<=0;vs_d<=0;rgb_d<=0;ink_d<=0;
  de_out<=0;hs_out<=0;vs_out<=0;r_out<=0;g_out<=0;b_out<=0;
 end else begin
  patch_g<=(SHOW_DEBUG_PATCH!=0) && de_in && x>=1104 && x<1232 && y>=544 && y<672;
  patch_valid_g<=debug_valid;patch_valid_q<=patch_valid_g;patch_valid_d<=patch_valid_q;
  patch_row_g<=patch_y[6:3];patch_col_g<=patch_x[6:3];
  patch_q<=patch_g;patch_col_q<=patch_col_g;
  patch_row_q<=debug_patch[{patch_row_g,4'b0}+:16];
  patch_d<=patch_q;patch_bit_d<=patch_row_q[patch_col_q];
  glyph_g<=glyph;row_g<=row;col_g<=col;active_g<=active;
  dark_g<=de_in && (y<160 || y>=648);
  rgb_g<={r_in,g_in,b_in};ink_g<=ink;
  de_g<=de_in;hs_g<=hs_in;vs_g<=vs_in;
  font_addr_q<={glyph_g,row_g};col_q<=col_g;
  active_q<=active_g;dark_q<=dark_g;
  rgb_q<=rgb_g;ink_q<=ink_g;
  de_q<=de_g;hs_q<=hs_g;vs_q<=vs_g;
  font_row<=font_rom[font_addr_q];col_d<=col_q;
  active_d<=active_q;dark_d<=dark_q;
  rgb_d<=rgb_q;ink_d<=ink_q;
  de_d<=de_q;hs_d<=hs_q;vs_d<=vs_q;
  de_out<=de_d;hs_out<=hs_d;vs_out<=vs_d;
  if(patch_d) {r_out,g_out,b_out}<=!patch_valid_d?24'h204080:
   patch_bit_d?24'h000000:24'hffffff;
  else if(active_d && font_row[31-col_d]) {r_out,g_out,b_out}<=ink_d;
  else if(dark_d) begin
   r_out<={2'b0,rgb_d[23:18]};g_out<={2'b0,rgb_d[15:10]};b_out<={2'b0,rgb_d[7:2]};
  end else {r_out,g_out,b_out}<=rgb_d;
 end
end
endmodule
`default_nettype wire
