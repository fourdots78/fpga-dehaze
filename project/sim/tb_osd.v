`timescale 1ns/1ps
module tb_osd_v12;
`include "cam2dvi/src/osd_layout.vh"
reg clk=0;always #5 clk=~clk;
reg rst_n=0,de=0,hs=0,vs=0;reg[2:0]sid=0,saved=0;reg valid=0,candidate=0,manual=0;
wire deo,hso,vso;wire[7:0]r,g,b;
video_osd dut(.clk(clk),.rst_n(rst_n),.de_in(de),.hs_in(hs),.vs_in(vs),
 .r_in(8'h80),.g_in(8'h60),.b_in(8'h40),.sign_id(sid),.saved_id(saved),.snapshot_valid(valid),.candidate(candidate),.display_mode(1'b1),.snapshot_manual(manual),.capture_count(8'd123),.source_ready(1'b1),.dbg_score(8'd15),.debug_patch({256{1'b1}}),.debug_valid(1'b1),
 .de_out(deo),.hs_out(hso),.vs_out(vso),.r_out(r),.g_out(g),.b_out(b));
reg[31:0]font[0:4095];reg[23:0]expected[0:3];reg[3:0]active=0;
reg[23:0]e,ink;reg[6:0]glyph;integer xx=0,yy=0,col,row,f,x,y,j,errors=0,checked=0,lit=0,patch_checked=0;
reg prevde=0,prevvs=0;
always @(posedge clk)if(rst_n)begin
 e=(yy<160||yy>=648)?24'h201810:24'h806040;
 glyph=0;col=0;row=0;ink=24'hf0f8ff;
 if(yy>=112&&yy<144&&xx>=24&&xx<856)begin
  if(sid!=0)glyph=name_glyph(sid,(xx-24)/32);
  else if(candidate)glyph=candidate_glyph((xx-24)/32);else glyph=scan_glyph((xx-24)/32);
  col=(xx-24)%32;row=yy-112;ink=24'hffe070;
 end else if(yy>=560&&yy<592&&xx>=208&&xx<1040)begin
  if(valid)glyph=manual?manual_glyph((xx-208)/32):name_glyph(saved,(xx-208)/32);else glyph=empty_glyph((xx-208)/32);
  col=(xx-208)%32;row=yy-560;ink=24'hffe070;
 end else if(yy>=600&&yy<632&&xx>=208&&xx<1040)begin
  if(valid&&!manual)glyph=info_glyph(saved,(xx-208)/32);
  col=(xx-208)%32;row=yy-600;
 end else if(yy>=648&&yy<680&&xx>=664&&xx<856)begin
  if(xx<728)glyph=counter_glyph((xx-664)/32);
  else if(xx<760)glyph=0;
  else if(xx<792)glyph=7'd88;
  else if(xx<824)glyph=7'd89;
  else glyph=7'd90;
  col=(xx-664)%32;row=yy-648;
 end
 if(font[glyph*32+row][31-col])begin e=ink;lit=lit+1;end
 for(j=3;j>0;j=j-1)expected[j]=expected[j-1];expected[0]=e;
 active={active[2:0],de&&((xx>=1104&&xx<1232&&yy>=544&&yy<672)||(yy>=112&&yy<144)||(yy>=560&&yy<592)||(yy>=600&&yy<632)||(yy>=648&&yy<680&&xx>=664&&xx<856))};
 if(vs&&!prevvs)begin xx=0;yy=0;end
 else begin if(de)xx=xx+1;else xx=0;if(prevde&&!de&&yy<719)yy=yy+1;end
 prevde=de;prevvs=vs;
 #1;if(active[3])begin checked=checked+1;if({r,g,b}!==expected[3])begin
  if(errors<4)$display("ERROR OSD got=%h expected=%h",{r,g,b},expected[3]);errors=errors+1;end end
end
initial begin
 $readmemh("cam2dvi/src/osd_font.hex",font);
 repeat(4)@(negedge clk);rst_n=1;
 for(f=0;f<5;f=f+1)begin
  sid=(f==2)?4:0;saved=(f==3)?4:0;valid=(f>=3);manual=(f==4);candidate=(f==1);
  vs=1;repeat(10)@(negedge clk);vs=0;repeat(10)@(negedge clk);
  for(y=0;y<720;y=y+1)begin
   for(x=0;x<1280;x=x+1)begin @(negedge clk);de=1;end
   @(negedge clk);de=0;repeat(6)@(negedge clk);
  end
 end
 repeat(10)@(negedge clk);
 if(errors||checked!=686080||lit==0)$fatal(1,"FAIL OSD errors=%0d checked=%0d lit=%0d",errors,checked,lit);
 $display("PASS V12 dynamic Chinese OSD: 686080 checked pixels; manual unconfirmed label and 123 capture counter; including the entire hidden debug-patch region, dynamic labels and timing");$finish;
end
endmodule
