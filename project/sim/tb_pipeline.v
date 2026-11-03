`timescale 1ns/1ps
module tb_pipeline_v12;
parameter INPUT_FILE="sim/sign_1.hex";
parameter EXPECTED_CLASS=2;
reg clk=0; always #5 clk=~clk;
reg rst_n=0,de=0,hs=0,vs=0;
reg [23:0] rgb=0;
wire deo,hso,vso; wire [7:0] r,g,b;
rgb_invert dut(.clk(clk),.rst_n(rst_n),.key_in(1'b1),.de_in(de),.hs_in(hs),.vs_in(vs),
 .r_in(rgb[23:16]),.g_in(rgb[15:8]),.b_in(rgb[7:0]),
 .de_out(deo),.hs_out(hso),.vs_out(vso),.r_out(r),.g_out(g),.b_out(b));
reg [15:0] frame[0:46079];
reg [24:0] dp=0,hp=0,vp=0;
integer f,x,y,ix,errors=0,checked=0; reg [15:0] p;
always @(posedge clk) if(rst_n) begin
 dp={dp[23:0],de}; hp={hp[23:0],hs}; vp={vp[23:0],vs}; #1;
 if({deo,hso,vso}!=={dp[24],hp[24],vp[24]}) begin
  if(errors<5) $display("ERROR sync at %t",$time);
  errors=errors+1;
 end
 if(deo) begin checked=checked+1; if(^{r,g,b}===1'bx) errors=errors+1; end
 if(dut.g_compare.probe_en && dut.a_de) $fatal(1,"FAIL active-video probe");
 if(dut.g_compare.u_compare.copying && dut.a_de) $fatal(1,"FAIL active-video snapshot copy");
end
always @(negedge clk) if(rst_n && dut.g_compare.u_det.state==40) $display("DIAG_PIPE bx=%0d by=%0d w=%0d h=%0d rot=%0d best=%0d score=%0d second=%0d slip=%0d dark=%0d patch=%h",dut.g_compare.u_det.bx,dut.g_compare.u_det.by,dut.g_compare.u_det.w,dut.g_compare.u_det.h,dut.g_compare.u_det.rotation,dut.g_compare.u_det.best_id,dut.g_compare.u_det.best_score,dut.g_compare.u_det.second_score,dut.g_compare.u_det.class_score[4],dut.g_compare.u_det.dark_count,dut.g_compare.u_det.canonical_patch);
initial begin
 $readmemh(INPUT_FILE,frame); repeat(4) @(negedge clk); rst_n=1;
 for(f=0;f<4;f=f+1) begin
  vs=1; repeat(40000) @(negedge clk); vs=0; repeat(20) @(negedge clk);
  for(y=0;y<720;y=y+1) begin
   for(x=0;x<1280;x=x+1) begin
    @(negedge clk); de=1; p=frame[(y/5)*320+x/4];
    rgb={p[15:11],p[15:13],p[10:5],p[10:9],p[4:0],p[4:2]};
   end
   @(negedge clk); de=0; hs=1; repeat(20) @(negedge clk); hs=0;
  end
  $display("FRAME %0d class=%0d saved=%0d ready=%0d count=%0d distance=%0d",f,dut.detected_class,dut.saved_class,dut.snapshot_ready,dut.capture_count,dut.match_distance);
 end
 repeat(40) @(negedge clk);
 if(dut.detected_class!=EXPECTED_CLASS || dut.saved_class!=EXPECTED_CLASS ||
    !dut.snapshot_ready || dut.capture_count!=1 || !dut.g_compare.box_valid) errors=errors+1;
 for(ix=0;ix<14400;ix=ix+1)
  if(dut.g_compare.u_compare.snapshot[ix]!==frame[((ix/160)*8/5)*320+(ix%160)*2]) begin
   if(errors<5) $display("ERROR snapshot ix=%0d got=%h expected=%h",ix,dut.g_compare.u_compare.snapshot[ix],frame[((ix/160)*8/5)*320+(ix%160)*2]);
   errors=errors+1;
  end
 if(checked!=3686400) errors=errors+1;
 if(errors) $fatal(1,"FAIL V12 pipeline errors=%0d checked=%0d",errors,checked);
 $display("PASS V12 full pipeline: 3686400 pixels, 25-cycle sync, enhanced classification, raw snapshot, confirmed box, atomic saved label");
 $finish;
end
endmodule
