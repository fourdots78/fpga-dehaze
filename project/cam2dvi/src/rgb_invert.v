//=============================================================================

// dehaze_as_rgb_invert.v  --  ★ 最省事的接入方式

//=============================================================================

// Current default SPLIT_SCREEN=1: original left, bounded-luminance enhancement

// right, white center divider. Raw RGB and side markers are delayed 16 cycles

// to match the processing path. Set SPLIT_SCREEN=0 for full processed output.

// 【怎么用】

//   本文件里的模块名故意叫 rgb_invert，接口和组长原来的 rgb_invert 完全一致。

//   所以：

//     1. 把 cam2dvi 工程里的 src/rgb_invert.v 备份成 rgb_invert.v.orig

//     2. 用本文件覆盖 src/rgb_invert.v

//     3. 【top.v 完全不用改】【.gprj 完全不用改】

//     4. 直接综合 → 烧录

//

//   为什么这样做：top.v 里已经写好了

//       rgb_invert u_probe (...)

//   并且外面已经包了 RGB565→888→(模块)→565 的转换。

//   只要模块名和端口不变，换掉文件内容即可，改动面最小、出错概率最低。

//

// 【内部做的事】

//   进来 RGB888（top.v 已经展开好）→ 直方图均衡去雾 → Sobel 边缘

//   → 按 MODE 组合 → 输出 RGB888（top.v 会压回 565）

//

// 【延迟】16 拍（去雾 8 + 边缘 8）。top.v 用 de_out 做写使能，会自动对齐。

//

// 【MODE 怎么选】

//   MODE = 0 : 只显示去雾画面      ← 第一次上板先用这个

//   MODE = 1 : 去雾画面 + 红色轮廓高亮  ← 答辩演示最抓眼球

//   MODE = 2 : 只显示边缘图（黑底白线）  ← 证明 Sobel 在工作

//

//   改下一行就行（在 module 里）：

//       dehaze_sobel_top #(... .MODE?)  ← 不对，MODE 是本模块的参数

//   正确改法：改本文件第 40 行的 parameter MODE = 0;

//

// 【分辨率】

//   WIDTH 必须等于实际一行像素数：720p 填 1280

//   ADDR_W 满足 2^ADDR_W >= 2*WIDTH：1280 填 12

//=============================================================================



`default_nettype none



module rgb_invert #(

    parameter integer WIDTH   = 1280,   // ★ 一行像素数，720p = 1280

    parameter integer ADDR_W  = 12,     // ★ 2^ADDR_W >= 2*WIDTH

    parameter integer MODE    = 0,      // ★ 0=去雾 1=去雾+红边 2=只看边缘

    parameter integer SPLIT_SCREEN = 1, // left: original; right: luma enhancement

    parameter integer SHOW_OSD = 1, // Chinese labels, adds two aligned cycles

    parameter integer SIDE_BY_SIDE = 1, // completed full-frame pair, not wipe

    parameter [7:0]   EDGE_TH = 8'd48   // MODE=1 时的边缘阈值

)(

    input  wire        clk,

    input  wire        rst_n,

    input  wire        key_in,     // mode button, F15, active low



    input  wire        de_in,

    input  wire        hs_in,

    input  wire        vs_in,

    input  wire [7:0]  r_in,

    input  wire [7:0]  g_in,

    input  wire [7:0]  b_in,



    output wire        de_out,

    output wire        hs_out,

    output wire        vs_out,

    output wire [7:0]  r_out,

    output wire [7:0]  g_out,

    output wire [7:0]  b_out

);



    //-------------------------------------------------------------------------

    // 算法核心

    //-------------------------------------------------------------------------

    wire        a_de, a_hs, a_vs;

    wire [7:0]  a_r, a_g, a_b;

    wire [7:0]  a_edge;



    dehaze_sobel_top #(

        .WIDTH  (WIDTH),

        .ADDR_W (ADDR_W)

    ) u_algo (

        .clk      (clk),

        .rst_n    (rst_n),

        .de_in    (de_in),

        .hs_in    (hs_in),

        .vs_in    (vs_in),

        .r_in     (r_in),

        .g_in     (g_in),

        .b_in     (b_in),

        .de_out   (a_de),

        .hs_out   (a_hs),

        .vs_out   (a_vs),

        .r_out    (a_r),

        .g_out    (a_g),

        .b_out    (a_b),

        .edge_out (a_edge)

    );



    //-------------------------------------------------------------------------

    // 按 MODE 选择显示效果

    //-------------------------------------------------------------------------

    reg [7:0] o_r, o_g, o_b;

    reg [23:0] raw_pipe [0:15];

    reg [15:0] right_pipe, divider_pipe;

    reg [ADDR_W-1:0] pixel_x;

    integer p;

    always @(posedge clk or negedge rst_n) begin

        if(!rst_n) begin

            for(p=0;p<16;p=p+1) raw_pipe[p] <= 24'd0;

            right_pipe<=0; divider_pipe<=0; pixel_x<=0;

        end else begin

            raw_pipe[0] <= {r_in,g_in,b_in};

            for(p=1;p<16;p=p+1) raw_pipe[p] <= raw_pipe[p-1];

            right_pipe <= {right_pipe[14:0],de_in && (pixel_x >= WIDTH/2)};

            divider_pipe <= {divider_pipe[14:0],de_in && (pixel_x == WIDTH/2)};

            if(de_in) pixel_x <= pixel_x + 1'b1;

            else pixel_x <= 0;

        end

    end



    always @(*) begin

        case (MODE)

            1: begin

                if (a_edge > EDGE_TH) begin

                    o_r = 8'hFF;  o_g = 8'h00;  o_b = 8'h00;   // 红边

                end else begin

                    o_r = a_r;    o_g = a_g;    o_b = a_b;

                end

            end

            2: begin

                o_r = a_edge; o_g = a_edge; o_b = a_edge;         // 灰度边缘

            end

            default: begin

                o_r = a_r;    o_g = a_g;    o_b = a_b;            // 纯去雾

            end

        endcase

        if(SPLIT_SCREEN != 0) begin

            if(divider_pipe[15]) begin

                o_r=8'd255; o_g=8'd255; o_b=8'd255;

            end else if(!right_pipe[15]) begin

                {o_r,o_g,o_b}=raw_pipe[15];

            end

        end

    end



    //-------------------------------------------------------------------------

    // Mode button: debounce + toggle between 2 display modes

    //   0 = raw + box (raw detection)   1 = dehaze + box (dehaze detection)

    //-------------------------------------------------------------------------

    wire display_mode,manual_capture,clear_capture;
    demo_controls u_controls(.clk(clk),.rst_n(rst_n),.key_n(key_in),
      .display_mode(display_mode),.manual_capture(manual_capture),.clear_capture(clear_capture));
    wire snapshot_manual,source_ready;
    wire c_de,c_hs,c_vs;

    wire [23:0] c_rgb;

    wire [2:0] detected_class,saved_class;

    wire [2:0] detector_last_class;

    wire candidate,snapshot_ready;

    wire [7:0] capture_count,match_distance;

    wire [7:0] dbg_score;   // original rolling score retained internally

    wire [255:0] debug_patch;

    wire debug_valid;

    wire [7:0] debug_distance;

    generate if(SIDE_BY_SIDE!=0)begin:g_compare

        wire frame_done,frame_valid,sample_en,probe_en,capture_trigger;

        wire [8:0] sx;wire [7:0] sy;

        wire [15:0] probe_addr,probe_data;
            wire [15:0] probe_data_enh;

        wire box_valid;wire [8:0] box_x;wire [7:0] box_y;

        wire [9:0] box_w;wire [8:0] box_h;

        video_compare u_compare(.clk(clk),.rst_n(rst_n),

            .de_in(a_de),.hs_in(a_hs),.vs_in(a_vs),

            .raw_in(raw_pipe[15]),.enhanced_in({a_r,a_g,a_b}),

            .probe_addr(probe_addr),.probe_en(probe_en),.probe_data(probe_data),
            .probe_data_enh(probe_data_enh),

            .frame_done(frame_done),.frame_valid(frame_valid),
            .manual_trigger(manual_capture),.clear_snapshot(clear_capture),.snapshot_manual(snapshot_manual),

            .sample_en(sample_en),.sample_x(sx),.sample_y(sy),

            .capture_trigger(capture_trigger),.snapshot_valid(snapshot_ready),.capture_count(capture_count),

            .capture_class(detected_class),.snapshot_class(saved_class),

            .box_valid(box_valid),.box_x(box_x),.box_y(box_y),.box_w(box_w),.box_h(box_h),

            .display_mode(display_mode),

            .de_out(c_de),.hs_out(c_hs),.vs_out(c_vs),.rgb_out(c_rgb));

        assign source_ready=frame_valid;
        sign_detector u_det(.clk(clk),.rst_n(rst_n),.frame_done(frame_done),

            .sample_en(sample_en),.sample_x(sx),.sample_y(sy),.sample_rgb({a_r,a_g,a_b}),.video_active(a_de),

            .probe_en(probe_en),.probe_addr(probe_addr),.probe_data(probe_data_enh),

            .current_class(detected_class),.last_class(detector_last_class),.capture_trigger(capture_trigger),

            .match_distance(match_distance),.candidate_valid(candidate),

            .box_valid(box_valid),.box_x(box_x),.box_y(box_y),.box_w(box_w),.box_h(box_h),

            .dbg_score(dbg_score),.debug_patch(debug_patch),

            .debug_valid(debug_valid),.debug_distance(debug_distance),

            .roi_valid(),.roi_x(),.roi_y(),.roi_w(),.roi_h());

    end else begin:g_wipe

        assign c_de=a_de;assign c_hs=a_hs;assign c_vs=a_vs;assign c_rgb={o_r,o_g,o_b};

        assign detected_class=0;assign saved_class=0;assign candidate=0;

        assign snapshot_manual=0;assign source_ready=0;
        assign snapshot_ready=0;assign capture_count=0;assign match_distance=255;

        assign detector_last_class=0;assign dbg_score=8'd255;

        assign debug_patch=0;assign debug_valid=0;assign debug_distance=255;

    end endgenerate

    generate if(SHOW_OSD != 0) begin: g_osd

        video_osd u_osd(.clk(clk),.rst_n(rst_n),

            .de_in(c_de),.hs_in(c_hs),.vs_in(c_vs),

            .r_in(c_rgb[23:16]),.g_in(c_rgb[15:8]),.b_in(c_rgb[7:0]),

            .display_mode(display_mode),.dbg_score(debug_distance),
            .snapshot_manual(snapshot_manual),.capture_count(capture_count),.source_ready(source_ready),

            .debug_patch(debug_patch),.debug_valid(debug_valid),

            .sign_id(detected_class),.saved_id(saved_class),.snapshot_valid(snapshot_ready),.candidate(candidate),

            .de_out(de_out),.hs_out(hs_out),.vs_out(vs_out),

            .r_out(r_out),.g_out(g_out),.b_out(b_out));

    end else begin: g_no_osd

    assign {r_out,g_out,b_out}=c_rgb;

    assign de_out = c_de;

    assign hs_out = c_hs;

    assign vs_out = c_vs;

    end endgenerate



endmodule



`default_nettype wire

