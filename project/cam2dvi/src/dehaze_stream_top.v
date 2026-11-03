`default_nettype none
// Basic dehazing only. Core already supplies the total 16-cycle delay.
// Legacy Sobel is deliberately not connected during this implementation.
module dehaze_sobel_top #(parameter integer WIDTH=1280,ADDR_W=12)(
 input wire clk,rst_n,de_in,hs_in,vs_in,
 input wire[7:0] r_in,g_in,b_in,
 output wire de_out,hs_out,vs_out,
 output wire[7:0] r_out,g_out,b_out,edge_out
);
 image_enhance #(.LATENCY(16),.WIDTH(WIDTH)) u_dehaze(
 .clk(clk),.rst_n(rst_n),.de_in(de_in),.hs_in(hs_in),.vs_in(vs_in),
 .r_in(r_in),.g_in(g_in),.b_in(b_in),.de_out(de_out),.hs_out(hs_out),.vs_out(vs_out),
 .r_out(r_out),.g_out(g_out),.b_out(b_out),.frame_end(),.dbg_state());
 assign edge_out=0;
endmodule
`default_nettype wire
