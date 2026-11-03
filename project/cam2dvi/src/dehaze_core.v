// ============================================================
//  dehaze_core : algorithm insertion point
//  B (algorithm) writes ONLY this module. Interface is FIXED.
// ============================================================
module dehaze_core (
    input  wire        clk,      // video pixel clock (video_clk)
    input  wire        rst_n,    // async reset, active low
    input  wire        vs,       // frame sync (use as HE statistics window)
    input  wire        de,       // pixel data valid
    input  wire [15:0] din,      // RGB565 {R[4:0],G[5:0],B[4:0]}
    output wire [15:0] dout,     // processed RGB565
    output wire        dout_de   // must be aligned with dout
);

    // ---- pass-through (replace with real algorithm) ----
    assign dout    = din;
    assign dout_de = de;

endmodule
