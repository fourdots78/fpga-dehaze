`default_nettype none
// V12: 320x144 separate color/dark components, four rotations plus mirrors.
// Experimental five-class template recognizer, NOT a general/safety-grade detector.
module sign_detector /* synthesis syn_romstyle="logic" */ #(
 parameter integer MAX_SCORE=19,
 parameter integer MIN_MARGIN=3,
 parameter integer SLIP_MAX_SCORE=19
)(
 input wire clk,rst_n,frame_done,sample_en,video_active,
 input wire [8:0] sample_x,input wire [7:0] sample_y,
 input wire [23:0] sample_rgb,
 output wire probe_en, output reg [15:0] probe_addr,input wire [15:0] probe_data,
 output reg [2:0] current_class,last_class,
 output reg capture_trigger, output reg [7:0] match_distance,
 output reg candidate_valid,box_valid,
 output reg [8:0] box_x,output reg [7:0] box_y,
 output reg [9:0] box_w,output reg [8:0] box_h,
   output wire [7:0] dbg_score,
 output reg roi_valid,output reg [8:0] roi_x,output reg [7:0] roi_y,
 output reg [9:0] roi_w,output reg [8:0] roi_h,
 output reg [255:0] debug_patch,
 output reg debug_valid,
 output reg [7:0] debug_distance
);
`include "T:/cam2dvi/src/sign_templates.vh"
// Eight-pixel cells preserve the white-paper gap between a sign and timber.
// Sixteen-pixel cells merged these separate regions in the actual test video.
localparam IDLE=0,LOAD_SLOT=13,ADDRESS=14,COORD=15,READ_ADDRESS=16,
 WAIT_READ=17,WAIT_EXTRA=18,WAIT_MORE=19,TAKE=20,MATCH=21,
 SELECT_INIT=22,SELECT_CLASS=23,RESULT=24,NEXT_SLOT=25,COMMIT=26,
 RANGE_INIT=31,RANGE_SCAN=32,MATCH_INIT=33,MATCH_ACC=34,
 RANGE_READ=36,MATCH_READ=37,VAR_READ=38,VAR_ACC=39,EVAL=40,LOCAL_WAIT=41;
reg [5:0] state /* synthesis syn_maxfan=16 syn_encoding="onehot" */;
reg [15:0] age;
wire [9:0] r={2'b0,sample_rgb[23:16]},g={2'b0,sample_rgb[15:8]},b={2'b0,sample_rgb[7:0]};
wire saturated_warm=(r>80)&&(g>65)&&(5*r>=4*g)&&(3*g>=r)&&(5*b<3*g)&&(5*b<3*r);
wire pale_warm=(r>170)&&(g>150)&&(r>g+15)&&(b<g+20)&&(b+20<r)&&(4*g>3*r);
wire local_done,local_candidate;
wire [35:0] local_x,local_h;wire [31:0] local_y;wire [39:0] local_w;wire [63:0] local_count;
sign_localizer u_localizer(.clk(clk),.rst_n(rst_n),.frame_done(frame_done),
 .sample_en(sample_en),.video_active(video_active),.warm(saturated_warm||pale_warm),.sx(sample_x),.sy(sample_y),
 .done(local_done),.candidate(local_candidate),.out_x(local_x),.out_y(local_y),.out_w(local_w),.out_h(local_h),.out_count(local_count));
reg [8:0] slot_x[0:3];reg [7:0] slot_y[0:3];
reg [9:0] slot_w[0:3];reg [8:0] slot_h[0:3];reg [15:0] slot_count[0:3];
reg [1:0] active_slot;
integer k;
reg [8:0] bx;reg [7:0] by;reg [9:0] w;reg [8:0] h;
reg [7:0] index;
reg [2:0] rotation;
wire [7:0] rotated_index=(rotation[1:0]==0)?index:(rotation[1:0]==1)?{~index[3:0],index[7:4]}:
 (rotation[1:0]==2)?~index:{index[3:0],~index[7:4]};
wire [7:0] canonical_index={rotated_index[7:4],rotation[2]?~rotated_index[3:0]:rotated_index[3:0]};
reg [7:0] intensity[0:255];
reg [7:0] intensity_q;
// Read and write are disjoint FSM phases; avoid an unsupported SP read-first mode.
always @(posedge clk) if(state==RANGE_READ||state==MATCH_READ) intensity_q<=intensity[index];
reg [7:0] min_luma,max_luma,dark_count;
wire [8:0] threshold_sum={1'b0,min_luma}+{1'b0,max_luma};
wire [7:0] threshold=threshold_sum[8:1];
wire sample_dark=intensity_q<=threshold;
reg [7:0] score[0:TEMPLATE_COUNT-1];
reg match_dark_q,match_mask_q;reg [TEMPLATE_COUNT-1:0] match_templates_q;
wire [TEMPLATE_COUNT-1:0] template_bits;
genvar ti;
generate for(ti=0;ti<TEMPLATE_COUNT;ti=ti+1)begin:g_templates
 wire [255:0] bits=sign_template(ti);
 assign template_bits[ti]=bits[canonical_index];
end endgenerate
reg [7:0] class_score[0:4];
reg [6:0] variant_id;reg [7:0] variant_score_q;reg [2:0] variant_class_q;
reg accept_q,better_q,early_q;
reg [255:0] match_patch,frame_patch;
wire [255:0] canonical_patch;
genvar pi;
generate for(pi=0;pi<256;pi=pi+1)begin:g_patch
 assign canonical_patch[pi]=(rotation[1:0]==0)?match_patch[pi]:
  (rotation[1:0]==1)?match_patch[(pi%16)*16+15-pi/16]:
  (rotation[1:0]==2)?match_patch[255-pi]:
  match_patch[(15-pi%16)*16+pi/16];
end endgenerate
reg [2:0] select_id,best_id,previous_class,frame_best_class;
// Original class windows retained; class 5 also covers enhanced printed-card calibration.
reg [7:0] dark_lo,dark_hi;
always @(*) begin
 case(best_id)
  3'd1: begin dark_lo=8'd25; dark_hi=8'd67; end
  3'd2: begin dark_lo=8'd9;  dark_hi=8'd31; end
  3'd3: begin dark_lo=8'd24; dark_hi=8'd46; end
  3'd4: begin dark_lo=8'd21; dark_hi=8'd36; end
  3'd5: begin dark_lo=8'd14; dark_hi=8'd56; end
  default: begin dark_lo=8'd0; dark_hi=8'd82; end
 endcase
end
reg [7:0] best_score,second_score,cooldown,frame_best_score;
   reg [7:0] frame_raw_min,dbg_acc,dbg_min;reg [4:0] dbg_cnt;
   assign dbg_score=dbg_min;
reg [8:0] frame_best_x;reg [7:0] frame_best_y;
reg [9:0] frame_best_w;reg [8:0] frame_best_h;
reg [2:0] stable;
reg [2:0] confirm_age;
reg [1:0] aborted_frames;
wire [2:0] selected_class=select_id+1'b1;
wire [7:0] selected_score=class_score[select_id];
wire [15:0] x_product=w*{1'b0,index[3:0],1'b1};
wire [14:0] y_product=h*{1'b0,index[7:4],1'b1};
reg [15:0] x_product_d;reg [14:0] y_product_d;
reg [8:0] px_d;reg [7:0] py_d;
wire [255:0] t0=sign_template(0),t1=sign_template(1),t2=sign_template(2),
 t3=sign_template(3),t4=sign_template(4),t5=sign_template(5),t6=sign_template(6);
wire [7:0] pr={probe_data[15:11],3'b0},pg={probe_data[10:5],2'b0},pb={probe_data[4:0],3'b0};
wire [9:0] luma_sum={2'b0,pr}+{1'b0,pg,1'b0}+{2'b0,pb};
wire [7:0] probe_luma=luma_sum[9:2];
assign probe_en=(state==READ_ADDRESS||state==WAIT_READ||state==WAIT_EXTRA||state==WAIT_MORE||state==TAKE)
 && !video_active && !sample_en && age<24000;
always @(posedge clk or negedge rst_n)begin
 if(!rst_n)begin
  state<=IDLE;age<=0;active_slot<=0;
  bx<=0;by<=0;w<=0;h<=0;index<=0;probe_addr<=0;rotation<=0;
  frame_best_x<=0;frame_best_y<=0;frame_best_w<=0;frame_best_h<=0;
  box_valid<=0;box_x<=0;box_y<=0;box_w<=0;box_h<=0;
  roi_valid<=0;roi_x<=0;roi_y<=0;roi_w<=0;roi_h<=0;
  x_product_d<=0;y_product_d<=0;px_d<=0;py_d<=0;
  min_luma<=255;max_luma<=0;dark_count<=0;select_id<=0;best_id<=0;
  match_dark_q<=0;match_mask_q<=0;match_templates_q<=0;
  match_patch<=0;frame_patch<=0;debug_patch<=0;debug_valid<=0;debug_distance<=255;
  best_score<=255;second_score<=255;previous_class<=0;frame_best_class<=0;frame_best_score<=255;
  frame_raw_min<=8'd255;dbg_acc<=8'd255;dbg_min<=8'd255;dbg_cnt<=5'd0;
  current_class<=0;last_class<=0;stable<=0;confirm_age<=0;aborted_frames<=0;cooldown<=0;capture_trigger<=0;match_distance<=255;candidate_valid<=0;
  for(k=0;k<4;k=k+1)begin slot_x[k]<=0;slot_y[k]<=0;slot_w[k]<=0;slot_h[k]<=0;slot_count[k]<=0;end
  variant_id<=0;variant_score_q<=255;variant_class_q<=0;accept_q<=0;better_q<=0;early_q<=0;
  for(k=0;k<TEMPLATE_COUNT;k=k+1)score[k]<=0;
  for(k=0;k<5;k=k+1)class_score[k]<=255;
 end else begin
  capture_trigger<=0;
  if(frame_done)begin
   state<=LOCAL_WAIT;age<=0;
   frame_best_class<=0;frame_best_score<=255;frame_raw_min<=255;candidate_valid<=0;active_slot<=0;box_valid<=0;roi_valid<=0;
   for(k=0;k<4;k=k+1)slot_count[k]<=0;
   if(cooldown!=0)cooldown<=cooldown-1'b1;
  end else begin
   if(state!=IDLE)age<=age+1'b1;
   case(state)
    LOCAL_WAIT:if(local_done)begin
     for(k=0;k<4;k=k+1)begin
      slot_x[k]<=local_x[k*9+:9];slot_y[k]<=local_y[k*8+:8];
      slot_w[k]<=local_w[k*10+:10];slot_h[k]<=local_h[k*9+:9];slot_count[k]<=local_count[k*16+:16];
     end
     candidate_valid<=local_candidate;active_slot<=0;state<=LOAD_SLOT;
    end
    LOAD_SLOT:begin
     if(slot_count[active_slot]==0)state<=NEXT_SLOT;
     else begin
      bx<=slot_x[active_slot];by<=slot_y[active_slot];w<=slot_w[active_slot];h<=slot_h[active_slot];
      index<=0;rotation<=0;min_luma<=255;max_luma<=0;state<=ADDRESS;
     end
    end
    ADDRESS:begin x_product_d<=x_product;y_product_d<=y_product;state<=COORD;end
    COORD:begin px_d<=bx+(x_product_d>>5);py_d<=by+(y_product_d>>5);state<=READ_ADDRESS;end
    READ_ADDRESS:begin probe_addr<=py_d*16'd320+px_d;state<=WAIT_READ;end
    WAIT_READ:state<=WAIT_EXTRA;
    WAIT_EXTRA:state<=WAIT_MORE;
    WAIT_MORE:state<=TAKE;
    TAKE:begin
     intensity[index]<=probe_luma;
     if(index==255)begin state<=RANGE_INIT;end
     else begin index<=index+1'b1;state<=ADDRESS;end
    end
    RANGE_INIT:begin min_luma<=255;max_luma<=0;index<=0;state<=RANGE_READ;end
    RANGE_READ:state<=RANGE_SCAN;
    RANGE_SCAN:begin
     if(SIGN_MASK[canonical_index])begin
      if(intensity_q<min_luma)min_luma<=intensity_q;
      if(intensity_q>max_luma)max_luma<=intensity_q;
     end
     if(index==255)state<=MATCH_INIT;else begin index<=index+1'b1;state<=RANGE_READ;end
    end
    MATCH_INIT:begin index<=0;dark_count<=0;for(k=0;k<TEMPLATE_COUNT;k=k+1)score[k]<=0;state<=MATCH_READ;end
    MATCH_READ:state<=MATCH;
    MATCH:begin
     match_dark_q<=sample_dark;match_mask_q<=SIGN_MASK[canonical_index];
     match_templates_q<=template_bits;
     state<=MATCH_ACC;
    end
    MATCH_ACC:begin
     match_patch<={match_dark_q,match_patch[255:1]};
     if(match_mask_q)begin
      if(match_dark_q)dark_count<=dark_count+1'b1;
      for(k=0;k<TEMPLATE_COUNT;k=k+1)score[k]<=score[k]+(match_dark_q^match_templates_q[k]);
     end
     if(index==255)state<=SELECT_INIT;else begin index<=index+1'b1;state<=MATCH_READ;end
    end
    SELECT_INIT:begin
     best_score<=255;second_score<=255;best_id<=0;select_id<=0;variant_id<=0;
     for(k=0;k<5;k=k+1)class_score[k]<=255;
     state<=VAR_READ;
    end
    VAR_READ:begin variant_score_q<=score[variant_id];variant_class_q<=sign_class(variant_id);state<=VAR_ACC;end
    VAR_ACC:begin
     if(variant_score_q<class_score[variant_class_q-1])class_score[variant_class_q-1]<=variant_score_q;
     if(variant_id==TEMPLATE_COUNT-1)state<=SELECT_CLASS;
     else begin variant_id<=variant_id+1'b1;state<=VAR_READ;end
    end
    SELECT_CLASS:begin
     if(selected_score<best_score)begin second_score<=best_score;best_score<=selected_score;best_id<=selected_class;end
     else if(selected_score<second_score)second_score<=selected_score;
     if(select_id==4)state<=EVAL;else select_id<=select_id+1'b1;
    end
    EVAL:begin
     better_q<=best_score<frame_raw_min;
     accept_q<=best_id!=1&&best_score<=((best_id==3'd5)?SLIP_MAX_SCORE:MAX_SCORE)&&second_score>=best_score+MIN_MARGIN&&dark_count>=dark_lo&&dark_count<=dark_hi&&
        {1'b0,max_luma}>={1'b0,min_luma}+9'd12&&best_score<frame_best_score;
     early_q<=rotation==3||(best_score<=4&&second_score>=best_score+8&&dark_count>=7&&dark_count<=55&&
        {1'b0,max_luma}>={1'b0,min_luma}+9'd24);
     state<=RESULT;
    end
    RESULT:begin
     if(better_q)begin
      frame_raw_min<=best_score;frame_patch<=canonical_patch;
      roi_valid<=1;roi_x<=bx;roi_y<=by;roi_w<=w;roi_h<=h;
     end
     if(accept_q)begin
      frame_best_class<=best_id;frame_best_score<=best_score;
      frame_best_x<=bx;frame_best_y<=by;frame_best_w<=w;frame_best_h<=h;
     end
     if(early_q)state<=NEXT_SLOT;
     else begin rotation<=rotation+1'b1;state<=RANGE_INIT;end
    end
    NEXT_SLOT:begin if(active_slot==3)state<=COMMIT;else begin active_slot<=active_slot+1'b1;state<=LOAD_SLOT;end end
    COMMIT:begin
     debug_valid<=(frame_raw_min!=255);debug_distance<=frame_raw_min;debug_patch<=frame_patch;
     state<=IDLE;match_distance<=frame_best_score;box_valid<=0;aborted_frames<=0;
     if(dbg_cnt==5'd31)begin
      dbg_min<=(frame_raw_min<dbg_acc)?frame_raw_min:dbg_acc;
      dbg_acc<=8'd255;dbg_cnt<=5'd0;
     end else begin
      dbg_acc<=(frame_raw_min<dbg_acc)?frame_raw_min:dbg_acc;
      dbg_cnt<=dbg_cnt+5'd1;
     end
     frame_raw_min<=8'd255;
     if(frame_best_class!=0)begin
      if(frame_best_class==previous_class&&(stable==3||confirm_age<5))begin
       if(stable<3)stable<=stable+1'b1;
       if(stable<2)confirm_age<=confirm_age+1'b1;
       if(stable>=2)begin
        confirm_age<=0;
        current_class<=frame_best_class;box_valid<=1;
        box_x<=frame_best_x;box_y<=frame_best_y;box_w<=frame_best_w;box_h<=frame_best_h;
        if(cooldown==0||frame_best_class!=last_class)begin capture_trigger<=1;last_class<=frame_best_class;cooldown<=120;end
       end
      end else begin previous_class<=frame_best_class;stable<=1;confirm_age<=1;current_class<=0;end
     end else begin
      current_class<=0;
      // Three matching positive observations within five completed frames.
      // A different positive class resets immediately; missing frames cannot
      // carry pending evidence indefinitely. Confirmed output clears on loss.
      if(stable>0&&stable<3&&confirm_age<4)confirm_age<=confirm_age+1'b1;
      else begin previous_class<=0;stable<=0;confirm_age<=0;end
     end
    end
    default:begin end
   endcase
   // Commit only fully evaluated candidates before the hard blanking deadline.
   if(state!=IDLE&&state!=COMMIT&&age>=22000)state<=COMMIT;
   // Bound blanking-time work; never steal the RAM port in active video.
   // Leave >=14,403 cycles for snapshot copy in normal 720p vertical blank.
   if(state!=IDLE&&(age>=24000||sample_en||video_active))begin
    state<=IDLE;candidate_valid<=0;box_valid<=0;roi_valid<=0;
    capture_trigger<=0;last_class<=last_class;cooldown<=cooldown;
    // Tolerate brief budget misses, but never retain a confirmed class or
    // pending confirmation indefinitely across aborted frames.
    if(aborted_frames<2)aborted_frames<=aborted_frames+1'b1;
    else begin current_class<=0;previous_class<=0;stable<=0;confirm_age<=0;match_distance<=255;end
   end
  end
 end
end
endmodule
// Sequential 8x8 connected components. No 720-bit variable mux/decoder bus.
module sign_localizer(
 input wire clk,rst_n,frame_done,sample_en,video_active,warm,
 input wire [8:0] sx,input wire [7:0] sy,
 output reg done,candidate,
 output wire [35:0] out_x,output wire [31:0] out_y,
 output wire [39:0] out_w,output wire [35:0] out_h,
 output wire [63:0] out_count
);
localparam INIT=0,READY=1,SEED_READ=2,SEED_TAKE=3,POP_READ=4,POP_TAKE=5,
 N_PREP=6,N_READ=7,N_TAKE=8,DIM=9,AREA=10,MIN0=11,MIN1=12,SAVE=13,
 FINISH=14,ABORT_CLEAR=15,HOLD=16,CHECK=17,POP_DELAY=18;
reg [4:0] state;
reg [24:0] tiles[0:719];
reg [10:0] queue[0:719];
reg [9:0] clean,seed,head,tail;
reg [5:0] seed_x,cur_x,nx_q;
reg [4:0] seed_y,cur_y,ny_q;
reg [2:0] direction;
reg [9:0] neighbor_addr;
reg [10:0] node;
reg queue_we;reg [9:0] queue_wa;reg [10:0] queue_wd;
reg [24:0] word_q,capture_old;
reg pending;reg [9:0] capture_addr;
reg [2:0] capture_x,capture_y;
wire [9:0] pixel_addr={sy[7:3],5'b0}+{sy[7:3],3'b0}+{4'b0,sx[8:3]};
wire collect=state==READY&&sample_en&&warm&&sx<320&&sy<144;
wire [24:0] updated=capture_old[24:16]!=0?{capture_old[24:16]+9'd1,
 ({1'b0,capture_x}<capture_old[15:12]?{1'b0,capture_x}:capture_old[15:12]),
 ({1'b0,capture_x}>capture_old[11:8]?{1'b0,capture_x}:capture_old[11:8]),
 ({1'b0,capture_y}<capture_old[7:4]?{1'b0,capture_y}:capture_old[7:4]),
 ({1'b0,capture_y}>capture_old[3:0]?{1'b0,capture_y}:capture_old[3:0])}:
 {9'd1,1'b0,capture_x,1'b0,capture_x,1'b0,capture_y,1'b0,capture_y};
// All writes share one RAM port. Component visits clear their count immediately.
// Scanning all 720 seeds leaves the RAM empty for the next complete frame.
always @(posedge clk)begin
 if(state==INIT||state==ABORT_CLEAR)tiles[clean]<=0;
 else if((state==SEED_TAKE||state==N_TAKE)&&word_q[24:16]!=0)
  tiles[state==SEED_TAKE?seed:neighbor_addr]<=0;
 else if(pending&&state==READY)tiles[capture_addr]<=updated;
 if(collect)capture_old<=(pending&&pixel_addr==capture_addr)?updated:tiles[pixel_addr];
 if(state==SEED_READ)word_q<=tiles[seed];
 if(state==N_READ)word_q<=tiles[neighbor_addr];
 if(state==POP_READ&&head<tail)node<=queue[head];
 if(queue_we)queue[queue_wa]<=queue_wd;
end
// One registered write port infers queue RAM instead of 720 decoded enables.
always @(posedge clk or negedge rst_n)begin
 if(!rst_n)begin queue_we<=0;queue_wa<=0;queue_wd<=0;end
 else begin
  queue_we<=((state==SEED_TAKE)||(state==N_TAKE&&tail<720))&&word_q[24:16]!=0;
  if(state==SEED_TAKE)begin queue_wa<=0;queue_wd<={seed_y,seed_x};end
  else if(state==N_TAKE)begin queue_wa<=tail;queue_wd<={ny_q,nx_q};end
 end
end
reg signed [6:0] nx;
reg signed [5:0] ny;
always @(*)begin
 nx=$signed({1'b0,cur_x});ny=$signed({1'b0,cur_y});
 case(direction)
  0:begin nx=nx-1;ny=ny-1;end
  1:ny=ny-1;
  2:begin nx=nx+1;ny=ny-1;end
  3:nx=nx-1;
  4:nx=nx+1;
  5:begin nx=nx-1;ny=ny+1;end
  6:ny=ny+1;
  7:begin nx=nx+1;ny=ny+1;end
 endcase
end
reg [8:0] xmin,xmax;reg [7:0] ymin,ymax;reg [15:0] total;
wire [8:0] read_x=(state==SEED_TAKE)?{seed_x,3'b0}:{nx_q,3'b0};
wire [7:0] read_y=(state==SEED_TAKE)?{seed_y,3'b0}:{ny_q,3'b0};
wire [8:0] word_x0=read_x+word_q[15:12],word_x1=read_x+word_q[11:8];
wire [7:0] word_y0=read_y+word_q[7:4],word_y1=read_y+word_q[3:0];
reg [9:0] width;reg [8:0] height;reg [18:0] area;
reg ranges,aspect;
reg plausible_q,replace_q;
wire plausible=ranges&&aspect&&(({total,3'b0}+{total,2'b0})>area)&&
 ({total,2'b0}<({2'b0,area}+({2'b0,area}<<1)));
reg [8:0] xs[0:3];reg [7:0] ys[0:3];
reg [9:0] ws[0:3];reg [8:0] hs[0:3];reg [15:0] counts[0:3];
reg [15:0] min_a,min_b;reg [1:0] id_a,id_b,replace_id;reg [15:0] min_count;
genvar z;
generate for(z=0;z<4;z=z+1)begin:outputs
 assign out_x[z*9+:9]=xs[z];assign out_y[z*8+:8]=ys[z];
 assign out_w[z*10+:10]=ws[z];assign out_h[z*9+:9]=hs[z];
 assign out_count[z*16+:16]=counts[z];
end endgenerate
integer i;
always @(posedge clk or negedge rst_n)begin
 if(!rst_n)begin
  state<=INIT;clean<=0;seed<=0;head<=0;tail<=0;seed_x<=0;seed_y<=0;cur_x<=0;cur_y<=0;
  nx_q<=0;ny_q<=0;direction<=0;neighbor_addr<=0;
  pending<=0;capture_addr<=0;capture_x<=0;capture_y<=0;
  xmin<=0;xmax<=0;ymin<=0;ymax<=0;total<=0;width<=0;height<=0;area<=0;ranges<=0;aspect<=0;
  min_a<=0;min_b<=0;id_a<=0;id_b<=0;replace_id<=0;min_count<=0;plausible_q<=0;replace_q<=0;
  done<=0;candidate<=0;
  for(i=0;i<4;i=i+1)begin xs[i]<=0;ys[i]<=0;ws[i]<=0;hs[i]<=0;counts[i]<=0;end
 end else begin
  done<=0;pending<=collect;
  if(collect)begin capture_addr<=pixel_addr;capture_x<=sx[2:0];capture_y<=sy[2:0];end
  case(state)
   INIT:begin if(clean==719)begin clean<=0;state<=READY;end else clean<=clean+1'b1;end
   READY:if(frame_done)begin
    seed<=0;seed_x<=0;seed_y<=0;candidate<=0;state<=SEED_READ;
    for(i=0;i<4;i=i+1)counts[i]<=0;
   end
   SEED_READ:state<=SEED_TAKE;
   SEED_TAKE:begin
    if(word_q[24:16]!=0)begin
     xmin<=word_x0;xmax<=word_x1;ymin<=word_y0;ymax<=word_y1;total<=word_q[24:16];
     head<=0;tail<=1;state<=POP_DELAY;
    end else if(seed==719)state<=FINISH;
    else begin
     seed<=seed+1'b1;
     if(seed_x==39)begin seed_x<=0;seed_y<=seed_y+1'b1;end else seed_x<=seed_x+1'b1;
     state<=SEED_READ;
    end
   end
   POP_DELAY:state<=POP_READ;
   POP_READ:begin if(head==tail)state<=DIM;else state<=POP_TAKE;end
   POP_TAKE:begin cur_x<=node[5:0];cur_y<=node[10:6];head<=head+1'b1;direction<=0;state<=N_PREP;end
   N_PREP:begin
    if(nx>=0&&nx<40&&ny>=0&&ny<18)begin
     nx_q<=nx[5:0];ny_q<=ny[4:0];neighbor_addr<=ny[4:0]*10'd40+nx[5:0];state<=N_READ;
    end else if(direction==7)state<=POP_DELAY;else direction<=direction+1'b1;
   end
   N_READ:state<=N_TAKE;
   N_TAKE:begin
    if(word_q[24:16]!=0&&tail<720)begin
     tail<=tail+1'b1;total<=total+word_q[24:16];
     if(word_x0<xmin)xmin<=word_x0;if(word_x1>xmax)xmax<=word_x1;
     if(word_y0<ymin)ymin<=word_y0;if(word_y1>ymax)ymax<=word_y1;
    end
    if(direction==7)state<=POP_DELAY;else begin direction<=direction+1'b1;state<=N_PREP;end
   end
   DIM:begin width<={1'b0,xmax}-{1'b0,xmin}+1'b1;height<={1'b0,ymax}-{1'b0,ymin}+1'b1;state<=AREA;end
   AREA:begin
    area<=width*height;
    ranges<=total>=25&&width>=8&&height>=8&&width<=240&&height<=140;
    aspect<=({width,1'b0}>=height)&&(width<={height,1'b0});state<=MIN0;
   end
   MIN0:begin
    if(counts[0]<=counts[1])begin min_a<=counts[0];id_a<=0;end else begin min_a<=counts[1];id_a<=1;end
    if(counts[2]<=counts[3])begin min_b<=counts[2];id_b<=2;end else begin min_b<=counts[3];id_b<=3;end
    state<=MIN1;
   end
   MIN1:begin
    if(min_a<=min_b)begin min_count<=min_a;replace_id<=id_a;end else begin min_count<=min_b;replace_id<=id_b;end
    state<=CHECK;
   end
   CHECK:begin plausible_q<=plausible;replace_q<=total>min_count;state<=SAVE;end
   SAVE:begin
    if(plausible_q)begin
     candidate<=1;
     if(replace_q)begin xs[replace_id]<=xmin;ys[replace_id]<=ymin;ws[replace_id]<=width;hs[replace_id]<=height;counts[replace_id]<=total;end
    end
    if(seed==719)state<=FINISH;
    else begin
     seed<=seed+1'b1;if(seed_x==39)begin seed_x<=0;seed_y<=seed_y+1'b1;end else seed_x<=seed_x+1'b1;
     state<=SEED_READ;
    end
   end
   FINISH:begin done<=1;state<=READY;end
   ABORT_CLEAR:begin
    if(clean==719)begin clean<=0;state<=HOLD;end else clean<=clean+1'b1;
   end
   HOLD:if(frame_done)state<=READY;
   default:begin clean<=0;state<=ABORT_CLEAR;end
  endcase
  // Unexpected video resumption discards the whole partially collected frame.
  if(((state>=SEED_READ&&state<=FINISH)||state==CHECK||state==POP_DELAY)&&(video_active||frame_done))begin
   state<=ABORT_CLEAR;clean<=0;done<=0;candidate<=0;
  end
 end
end
endmodule

`default_nettype wire
