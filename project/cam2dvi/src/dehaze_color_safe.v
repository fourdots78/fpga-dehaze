`default_nettype none
// V23: natural dark-channel luminance scattering-model inversion (A=240,
// omega=0.8, transmission>=1/3). Common RGB correction preserves color
// differences. Shadow floor retains floor(min/4)+floor(min/8) of the input.
// No per-channel contrast amplification. Same 16-cycle RGB/sync latency.
module image_enhance #(parameter integer LATENCY=16,WIDTH=1280)(
 input wire clk,rst_n,de_in,hs_in,vs_in,
 input wire [7:0] r_in,g_in,b_in,
 output wire de_out,hs_out,vs_out,
 output wire [7:0] r_out,g_out,b_out,
 output wire frame_end,output wire [7:0] dbg_state
) /* synthesis syn_romstyle="logic" */;
 function [7:0] min8;
 input [7:0] a,b;begin min8=(a<b)?a:b;end
 endfunction
 function [7:0] max8;
 input [7:0] a,b;begin max8=(a>b)?a:b;end
 endfunction
 function [13:0] extra_rom;
 input [7:0] d;
 begin case(d)
 `include "T:/cam2dvi/src/gain_extra_rom.vh"
 default:extra_rom=0;
 endcase end
 endfunction
 function [7:0] add_correction;
 input [7:0] value;input signed [8:0] correction;
 reg signed [9:0] total;
 begin
 total=$signed({2'b00,value})+$signed({correction[8],correction});
 if(total<0)add_correction=0;else if(total>255)add_correction=255;else add_correction=total[7:0];
 end
 endfunction
 reg [23:0] rgb[0:8];
 reg [15:0] dp,hp,vp;
 reg [7:0] dark1,history[0:13],horizontal3,current4,dark8;
 wire [7:0] h0[0:15],h1[0:7],h2[0:3];
 reg [7:0] horizontal2[0:3];
 assign h0[0]=dark1;assign h0[15]=255;
 genvar i;
 generate
 for(i=0;i<14;i=i+1)begin:g_h0
  assign h0[i+1]=history[i];
 end
 for(i=0;i<8;i=i+1)begin:g_h1
  assign h1[i]=min8(h0[2*i],h0[2*i+1]);
 end
 for(i=0;i<4;i=i+1)begin:g_h2
  assign h2[i]=min8(h1[2*i],h1[2*i+1]);
 end
 endgenerate
 localparam COL_W=$clog2(WIDTH+1);
 reg [COL_W-1:0] column,row_samples;
 reg [3:0] row_slot;
 reg [14:0] valid_rows,mask4;
 reg de3_prev,vs3_prev;
 wire frame3=vp[3]&&!vs3_prev;
 wire [7:0] q4[0:14];
 generate for(i=0;i<15;i=i+1)begin:g_rows
  reg [7:0] row_memory[0:WIDTH-1];
  reg [7:0] read_q;
  always @(posedge clk)begin
   if(rst_n && dp[3] && !frame3 && row_slot==i)begin
    row_memory[column]<=horizontal3;read_q<=horizontal3;
   end else read_q<=row_memory[column];
  end
  assign q4[i]=read_q;
 end endgenerate
 always @(posedge clk or negedge rst_n)begin
  if(!rst_n)begin
   column<=0;row_samples<=0;row_slot<=0;valid_rows<=0;de3_prev<=0;vs3_prev<=0;
  end else begin
   de3_prev<=dp[3];vs3_prev<=vp[3];
   if(frame3)begin column<=0;row_samples<=0;row_slot<=0;valid_rows<=0;end
   else if(dp[3])begin
    column<=(column==WIDTH-1)?0:column+1'b1;row_samples<=row_samples+1'b1;
   end else begin
    column<=0;row_samples<=0;
    if(de3_prev)begin
     valid_rows[row_slot]<=(row_samples==WIDTH);row_slot<=(row_slot==14)?0:row_slot+1'b1;
    end
   end
  end
 end
 wire [7:0] v0[0:15];
 assign v0[0]=current4;
 generate for(i=0;i<15;i=i+1)begin:g_v0
  assign v0[i+1]=mask4[i]?q4[i]:8'd255;
 end endgenerate
 reg [7:0] v5[0:7],v6[0:3],v7[0:1];
 wire [9:0] luma_sum={2'b0,rgb[8][23:16]}+{1'b0,rgb[8][15:8],1'b0}+{2'b0,rgb[8][7:0]};
 wire [7:0] pixel_min=min8(min8(rgb[8][23:16],rgb[8][15:8]),rgb[8][7:0]);
 wire [7:0] pixel_max=max8(max8(rgb[8][23:16],rgb[8][15:8]),rgb[8][7:0]);
 reg [13:0] extra9;
 reg signed [8:0] luma_delta9;
 reg [7:0] floor9,headroom9,floor10,headroom10;
 reg signed [23:0] product10;
 wire signed [23:0] proposed=product10>>>12;
 reg signed [8:0] correction11;
 reg [23:0] raw9,raw10,raw11,rgb12,rgb13,rgb14,rgb15;
 reg vs_prev;
 integer p;
 always @(posedge clk or negedge rst_n)begin
  if(!rst_n)begin
   for(p=0;p<9;p=p+1)rgb[p]<=0;
   for(p=0;p<14;p=p+1)history[p]<=255;
   for(p=0;p<4;p=p+1)horizontal2[p]<=255;
   for(p=0;p<8;p=p+1)v5[p]<=255;
   for(p=0;p<4;p=p+1)v6[p]<=255;
   for(p=0;p<2;p=p+1)v7[p]<=255;
   dark1<=255;horizontal3<=255;current4<=255;mask4<=0;dark8<=0;
   extra9<=0;luma_delta9<=0;floor9<=0;headroom9<=0;floor10<=0;headroom10<=0;product10<=0;correction11<=0;
   raw9<=0;raw10<=0;raw11<=0;rgb12<=0;rgb13<=0;rgb14<=0;rgb15<=0;
   dp<=0;hp<=0;vp<=0;vs_prev<=0;
  end else begin
   rgb[0]<={r_in,g_in,b_in};for(p=1;p<9;p=p+1)rgb[p]<=rgb[p-1];
   dark1<=min8(min8(rgb[0][23:16],rgb[0][15:8]),rgb[0][7:0]);
   if(dp[1])begin history[0]<=dark1;for(p=1;p<14;p=p+1)history[p]<=history[p-1];end
   else for(p=0;p<14;p=p+1)history[p]<=255;
   for(p=0;p<4;p=p+1)horizontal2[p]<=h2[p];
   horizontal3<=min8(min8(horizontal2[0],horizontal2[1]),min8(horizontal2[2],horizontal2[3]));
   current4<=horizontal3;mask4<=valid_rows & ~(15'b1<<row_slot);
   for(p=0;p<8;p=p+1)v5[p]<=min8(v0[2*p],v0[2*p+1]);
   for(p=0;p<4;p=p+1)v6[p]<=min8(v5[2*p],v5[2*p+1]);
   for(p=0;p<2;p=p+1)v7[p]<=min8(v6[2*p],v6[2*p+1]);
   dark8<=min8(v7[0],v7[1]);
   extra9<=extra_rom(dark8);
   luma_delta9<=$signed({1'b0,luma_sum[9:2]})-9'sd240;
   floor9<=pixel_min-(pixel_min>>2)-(pixel_min>>3);headroom9<=8'd255-pixel_max;raw9<=rgb[8];
   product10<=luma_delta9*$signed({1'b0,extra9});floor10<=floor9;headroom10<=headroom9;raw10<=raw9;
   if(proposed<-$signed({1'b0,floor10}))correction11<=-$signed({1'b0,floor10});
   else if(proposed>$signed({1'b0,headroom10}))correction11<=$signed({1'b0,headroom10});
   else correction11<=proposed[8:0];
   raw11<=raw10;
   rgb12<={add_correction(raw11[23:16],correction11),add_correction(raw11[15:8],correction11),add_correction(raw11[7:0],correction11)};
   rgb13<=rgb12;rgb14<=rgb13;rgb15<=rgb14;
   dp<={dp[14:0],de_in};hp<={hp[14:0],hs_in};vp<={vp[14:0],vs_in};vs_prev<=vs_out;
  end
 end
 assign {r_out,g_out,b_out}=rgb15;
 assign de_out=dp[15];assign hs_out=hp[15];assign vs_out=vp[15];
 assign frame_end=vs_out&&!vs_prev;assign dbg_state=8'h23;
endmodule
`default_nettype wire
