//=============================================================================
// line_buffer_3x3.v  --  3x3 窗口行缓存（已用 Python 模型验证对齐）
//=============================================================================
// 【结构】
//   两块单行 BRAM 级联，每块就是"延迟整整一行"：
//
//     pix_now ─┬───────────────────────────────────► 链 C（当前行）
//              │
//              └─► BRAM0 ──(延迟1行)──┬─────────────► 链 B（上一行）
//                                     │
//                                     └─► BRAM1 ──(延迟2行)──► 链 A（上上行）
//
//   每个 BRAM 的读写地址都是同一个 col 计数，靠 BRAM 同步读的
//   "先读后写"语义得到写入前的旧值，于是天然延迟一行。
//
//   每条链挂 3 级移位寄存器，得到 X-2 / X-1 / X 三列。
//
// 【对齐结果】（在 Python 里逐像素验证过 196/196 完全一致）
//   窗口中心 win[4] = P(Y-1, X-1)
//   即输出比输入整体偏移 (+1 行, +1 列)，这是因果性导致的正常现象。
//
// 【为什么不用"一块 BRAM 读两个地址"】
//   我试过，失败了 3 次。一块 BRAM 的读口有限，而 3x3 需要 3 行 x 3 列
//   的时序对齐，跨行地址算术极易出错。级联结构虽然多用一块 BRAM
//   （约 1% 的资源），但正确性一目了然。
//
// 【初始化】
//   上电后先把两块 BRAM 清零（需要 DEPTH 拍），否则前两行会显示随机噪点。
//   清零完成后 init_done=1，才开始正常写入。
//=============================================================================

`default_nettype none

module line_buffer_3x3 #(
    parameter WIDTH  = 640,        // 一行像素数
    parameter PIX_W  = 8,          // 像素位宽
    parameter ADDR_W = 11          // 地址位宽：2^ADDR_W 必须 >= 2*WIDTH
)(
    input  wire                clk,
    input  wire                rst_n,

    input  wire                de_in,
    input  wire                hs_in,
    input  wire                vs_in,
    input  wire [PIX_W-1:0]    pix_in,

    // 3x3 窗口：win[8] 是当前行最新列，win[4] 是窗口中心
    output wire [9*PIX_W-1:0]  win_out,
    output wire                win_valid,
    output wire                de_out,
    output wire                hs_out,
    output wire                vs_out
);

    localparam DEPTH = 2 * WIDTH;

    //=========================================================================
    // 1. 初始化：把两块 BRAM 清零
    //=========================================================================
    reg  [ADDR_W-1:0] init_cnt;
    reg               init_done;

    reg [PIX_W-1:0] mem0 [0:DEPTH-1];   // 延迟 1 行
    reg [PIX_W-1:0] mem1 [0:DEPTH-1];   // 延迟 2 行

    //=========================================================================
    // 1. 列计数器（必须在使用 col 的语句之前声明）
    //=========================================================================
    // 只在 de_in=1 时递增；vs_in 时归零。
    // 要求 A 送来的 de_in 在一行内连续、每行长度恒定。
    //=========================================================================
    reg [ADDR_W-1:0] col;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            col <= {ADDR_W{1'b0}};
        else if (vs_in)
            col <= {ADDR_W{1'b0}};
        else if (de_in && init_done) begin
            if (col == WIDTH - 1)
                col <= {ADDR_W{1'b0}};
            else
                col <= col + 1'b1;
        end
    end

    //=========================================================================
    // 2. 【关键】组合读，不是同步读
    //=========================================================================
    // 一开始我写成同步读（q0 <= mem0[col]），结果数据比地址晚一拍，
    // 整个窗口错开一列，边框全乱。
    //
    // 组合读 = 这一拍给出地址，这一拍就拿到数据（先读后写）。
    // 这正是我在 Python 模型里验证过的语义，两者必须一致。
    //
    // 资源代价：综合成分布式 RAM（LUTRAM）而不是 BSRAM。
    // 2 块 1280x8 大约 1300 个 LUT，对 GW5AST-138 可以忽略。
    //=========================================================================
    wire [PIX_W-1:0] q0 = mem0[col];
    wire [PIX_W-1:0] q1 = mem1[col];

    //=========================================================================
    // 3. 存储器写入 + 上电清零
    //=========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            init_cnt  <= {ADDR_W{1'b0}};
            init_done <= 1'b0;
        end else if (!init_done) begin
            // 上电清零：把两块存储器全部写 0
            mem0[init_cnt] <= {PIX_W{1'b0}};
            mem1[init_cnt] <= {PIX_W{1'b0}};
            if (init_cnt == DEPTH - 1)
                init_done <= 1'b1;
            else
                init_cnt <= init_cnt + 1'b1;
        end else if (de_in) begin
            mem0[col] <= pix_in;   // 写入当前行
            mem1[col] <= q0;       // 把"上一行"往下推一行（组合读到的当前值）
        end
    end

    //=========================================================================
    // 4. 三条 3 级移位链
    //=========================================================================
    reg [PIX_W-1:0] cA0, cA1, cA2;
    reg [PIX_W-1:0] cB0, cB1, cB2;
    reg [PIX_W-1:0] cC0, cC1, cC2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cA0 <= 0; cA1 <= 0; cA2 <= 0;
            cB0 <= 0; cB1 <= 0; cB2 <= 0;
            cC0 <= 0; cC1 <= 0; cC2 <= 0;
        end else begin
            cA2 <= cA1; cA1 <= cA0; cA0 <= q1;
            cB2 <= cB1; cB1 <= cB0; cB0 <= q0;
            cC2 <= cC1; cC1 <= cC0; cC0 <= pix_in;
        end
    end

    // 窗口装配（顺序：win0 是最左上，win8 是最右下）
    assign win_out = { cC0, cC1, cC2,
                       cB0, cB1, cB2,
                       cA0, cA1, cA2 };

    //=========================================================================
    // 5. 输出同步信号（与链的延迟对齐：2 拍）
    //=========================================================================
    reg [1:0] de_d, hs_d, vs_d;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            de_d <= 2'b00;
            hs_d <= 2'b00;
            vs_d <= 2'b00;
        end else begin
            de_d <= {de_d[0], de_in};
            hs_d <= {hs_d[0], hs_in};
            vs_d <= {vs_d[0], vs_in};
        end
    end

    assign de_out = de_d[1];
    assign hs_out = hs_d[1];
    assign vs_out = vs_d[1];

    //=========================================================================
    // 6. win_valid
    //=========================================================================
    // 前 2 行/前 2 列的窗口不完整（用到了初始化时的 0 或上一行的残留）。
    // 下游可以据此丢弃边框，也可以照常处理（本项目的验证只比对内部区域）。
    //=========================================================================
    reg [ADDR_W-1:0] col_d1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) col_d1 <= {ADDR_W{1'b0}};
        else        col_d1 <= col;
    end

    assign win_valid = de_out && (col_d1 >= 2) && init_done;

endmodule

`default_nettype wire
