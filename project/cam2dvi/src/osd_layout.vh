// Generated V4 font lookup. 32x32 cells, 7-bit glyph index.
function [6:0] title_glyph; input [5:0] index; begin case(index)
6'd0: title_glyph=7'd1;
6'd1: title_glyph=7'd2;
6'd2: title_glyph=7'd3;
6'd3: title_glyph=7'd4;
6'd4: title_glyph=7'd5;
6'd5: title_glyph=7'd6;
6'd6: title_glyph=7'd7;
6'd7: title_glyph=7'd8;
6'd8: title_glyph=7'd9;
6'd9: title_glyph=7'd10;
6'd10: title_glyph=7'd11;
6'd11: title_glyph=7'd12;
6'd12: title_glyph=7'd13;
6'd13: title_glyph=7'd14;
6'd14: title_glyph=7'd15;
6'd15: title_glyph=7'd16;
6'd16: title_glyph=7'd17;
default: title_glyph=0; endcase end endfunction
localparam integer TITLE_LENGTH=17;
function [6:0] left_glyph; input [5:0] index; begin case(index)
6'd0: left_glyph=7'd18;
6'd1: left_glyph=7'd19;
6'd2: left_glyph=7'd20;
6'd3: left_glyph=7'd21;
6'd4: left_glyph=7'd22;
6'd5: left_glyph=7'd23;
default: left_glyph=0; endcase end endfunction
localparam integer LEFT_LENGTH=6;
function [6:0] right_glyph; input [5:0] index; begin case(index)
6'd0: right_glyph=7'd24;
6'd1: right_glyph=7'd25;
6'd2: right_glyph=7'd20;
6'd3: right_glyph=7'd21;
6'd4: right_glyph=7'd22;
6'd5: right_glyph=7'd23;
default: right_glyph=0; endcase end endfunction
localparam integer RIGHT_LENGTH=6;
function [6:0] footer_glyph; input [5:0] index; begin case(index)
6'd0: footer_glyph=7'd26;
6'd1: footer_glyph=7'd27;
6'd2: footer_glyph=7'd18;
6'd3: footer_glyph=7'd28;
6'd4: footer_glyph=7'd0;
6'd5: footer_glyph=7'd0;
6'd6: footer_glyph=7'd29;
6'd7: footer_glyph=7'd30;
6'd8: footer_glyph=7'd31;
6'd9: footer_glyph=7'd32;
6'd10: footer_glyph=7'd33;
6'd11: footer_glyph=7'd34;
6'd12: footer_glyph=7'd35;
default: footer_glyph=0; endcase end endfunction
localparam integer FOOTER_LENGTH=13;
function [6:0] scan_glyph; input [5:0] index; begin case(index)
6'd0: scan_glyph=7'd36;
6'd1: scan_glyph=7'd37;
6'd2: scan_glyph=7'd38;
6'd3: scan_glyph=7'd0;
6'd4: scan_glyph=7'd0;
6'd5: scan_glyph=7'd39;
6'd6: scan_glyph=7'd40;
6'd7: scan_glyph=7'd41;
6'd8: scan_glyph=7'd42;
6'd9: scan_glyph=7'd43;
6'd10: scan_glyph=7'd44;
default: scan_glyph=0; endcase end endfunction
localparam integer SCAN_LENGTH=11;
function [6:0] candidate_glyph; input [5:0] index; begin case(index)
6'd0: candidate_glyph=7'd45;
6'd1: candidate_glyph=7'd46;
6'd2: candidate_glyph=7'd47;
6'd3: candidate_glyph=7'd48;
6'd4: candidate_glyph=7'd9;
6'd5: candidate_glyph=7'd49;
6'd6: candidate_glyph=7'd0;
6'd7: candidate_glyph=7'd0;
6'd8: candidate_glyph=7'd50;
6'd9: candidate_glyph=7'd51;
6'd10: candidate_glyph=7'd40;
6'd11: candidate_glyph=7'd41;
default: candidate_glyph=0; endcase end endfunction
localparam integer CANDIDATE_LENGTH=12;
function [6:0] empty_glyph; input [5:0] index; begin case(index)
6'd0: empty_glyph=7'd52;
6'd1: empty_glyph=7'd53;
6'd2: empty_glyph=7'd54;
6'd3: empty_glyph=7'd55;
6'd4: empty_glyph=7'd0;
6'd5: empty_glyph=7'd0;
6'd6: empty_glyph=7'd56;
6'd7: empty_glyph=7'd57;
6'd8: empty_glyph=7'd58;
6'd9: empty_glyph=7'd59;
6'd10: empty_glyph=7'd60;
6'd11: empty_glyph=7'd61;
default: empty_glyph=0; endcase end endfunction
localparam integer EMPTY_LENGTH=12;
function [6:0] snap_glyph; input [5:0] index; begin case(index)
6'd0: snap_glyph=7'd62;
6'd1: snap_glyph=7'd63;
6'd2: snap_glyph=7'd54;
6'd3: snap_glyph=7'd55;
default: snap_glyph=0; endcase end endfunction
localparam integer SNAP_LENGTH=4;
function [6:0] n1_glyph; input [5:0] index; begin case(index)
6'd0: n1_glyph=7'd10;
6'd1: n1_glyph=7'd11;
6'd2: n1_glyph=7'd64;
6'd3: n1_glyph=7'd65;
6'd4: n1_glyph=7'd66;
6'd5: n1_glyph=7'd9;
6'd6: n1_glyph=7'd49;
default: n1_glyph=0; endcase end endfunction
localparam integer N1_LENGTH=7;
function [6:0] n2_glyph; input [5:0] index; begin case(index)
6'd0: n2_glyph=7'd10;
6'd1: n2_glyph=7'd11;
6'd2: n2_glyph=7'd64;
6'd3: n2_glyph=7'd67;
6'd4: n2_glyph=7'd68;
6'd5: n2_glyph=7'd69;
6'd6: n2_glyph=7'd70;
6'd7: n2_glyph=7'd9;
6'd8: n2_glyph=7'd49;
default: n2_glyph=0; endcase end endfunction
localparam integer N2_LENGTH=9;
function [6:0] n3_glyph; input [5:0] index; begin case(index)
6'd0: n3_glyph=7'd10;
6'd1: n3_glyph=7'd11;
6'd2: n3_glyph=7'd64;
6'd3: n3_glyph=7'd67;
6'd4: n3_glyph=7'd68;
6'd5: n3_glyph=7'd30;
6'd6: n3_glyph=7'd71;
6'd7: n3_glyph=7'd9;
6'd8: n3_glyph=7'd49;
default: n3_glyph=0; endcase end endfunction
localparam integer N3_LENGTH=9;
function [6:0] n4_glyph; input [5:0] index; begin case(index)
6'd0: n4_glyph=7'd10;
6'd1: n4_glyph=7'd11;
6'd2: n4_glyph=7'd64;
6'd3: n4_glyph=7'd67;
6'd4: n4_glyph=7'd68;
6'd5: n4_glyph=7'd72;
6'd6: n4_glyph=7'd73;
6'd7: n4_glyph=7'd9;
6'd8: n4_glyph=7'd49;
default: n4_glyph=0; endcase end endfunction
localparam integer N4_LENGTH=9;
function [6:0] n5_glyph; input [5:0] index; begin case(index)
6'd0: n5_glyph=7'd10;
6'd1: n5_glyph=7'd11;
6'd2: n5_glyph=7'd64;
6'd3: n5_glyph=7'd74;
6'd4: n5_glyph=7'd75;
6'd5: n5_glyph=7'd9;
6'd6: n5_glyph=7'd49;
default: n5_glyph=0; endcase end endfunction
localparam integer N5_LENGTH=7;
function [6:0] i1_glyph; input [5:0] index; begin case(index)
6'd0: i1_glyph=7'd76;
6'd1: i1_glyph=7'd77;
6'd2: i1_glyph=7'd65;
6'd3: i1_glyph=7'd66;
6'd4: i1_glyph=7'd0;
6'd5: i1_glyph=7'd0;
6'd6: i1_glyph=7'd78;
6'd7: i1_glyph=7'd15;
6'd8: i1_glyph=7'd79;
6'd9: i1_glyph=7'd30;
6'd10: i1_glyph=7'd80;
6'd11: i1_glyph=7'd81;
6'd12: i1_glyph=7'd30;
default: i1_glyph=0; endcase end endfunction
localparam integer I1_LENGTH=13;
function [6:0] i2_glyph; input [5:0] index; begin case(index)
6'd0: i2_glyph=7'd67;
6'd1: i2_glyph=7'd68;
6'd2: i2_glyph=7'd69;
6'd3: i2_glyph=7'd70;
6'd4: i2_glyph=7'd0;
6'd5: i2_glyph=7'd0;
6'd6: i2_glyph=7'd82;
6'd7: i2_glyph=7'd83;
6'd8: i2_glyph=7'd84;
6'd9: i2_glyph=7'd85;
default: i2_glyph=0; endcase end endfunction
localparam integer I2_LENGTH=10;
function [6:0] i3_glyph; input [5:0] index; begin case(index)
6'd0: i3_glyph=7'd67;
6'd1: i3_glyph=7'd68;
6'd2: i3_glyph=7'd30;
6'd3: i3_glyph=7'd71;
6'd4: i3_glyph=7'd0;
6'd5: i3_glyph=7'd0;
6'd6: i3_glyph=7'd78;
6'd7: i3_glyph=7'd15;
6'd8: i3_glyph=7'd79;
6'd9: i3_glyph=7'd30;
default: i3_glyph=0; endcase end endfunction
localparam integer I3_LENGTH=10;
function [6:0] i4_glyph; input [5:0] index; begin case(index)
6'd0: i4_glyph=7'd67;
6'd1: i4_glyph=7'd68;
6'd2: i4_glyph=7'd72;
6'd3: i4_glyph=7'd73;
6'd4: i4_glyph=7'd0;
6'd5: i4_glyph=7'd0;
6'd6: i4_glyph=7'd78;
6'd7: i4_glyph=7'd15;
6'd8: i4_glyph=7'd79;
6'd9: i4_glyph=7'd30;
default: i4_glyph=0; endcase end endfunction
localparam integer I4_LENGTH=10;
function [6:0] i5_glyph; input [5:0] index; begin case(index)
6'd0: i5_glyph=7'd67;
6'd1: i5_glyph=7'd68;
6'd2: i5_glyph=7'd86;
6'd3: i5_glyph=7'd75;
6'd4: i5_glyph=7'd0;
6'd5: i5_glyph=7'd0;
6'd6: i5_glyph=7'd78;
6'd7: i5_glyph=7'd15;
6'd8: i5_glyph=7'd79;
6'd9: i5_glyph=7'd30;
default: i5_glyph=0; endcase end endfunction
localparam integer I5_LENGTH=10;
function [6:0] name_glyph; input [2:0] id; input [5:0] index; begin case(id)
3'd1: name_glyph=n1_glyph(index);
3'd2: name_glyph=n2_glyph(index);
3'd3: name_glyph=n3_glyph(index);
3'd4: name_glyph=n4_glyph(index);
3'd5: name_glyph=n5_glyph(index);
default: name_glyph=0; endcase end endfunction
function [6:0] info_glyph; input [2:0] id; input [5:0] index; begin case(id)
3'd1: info_glyph=i1_glyph(index);
3'd2: info_glyph=i2_glyph(index);
3'd3: info_glyph=i3_glyph(index);
3'd4: info_glyph=i4_glyph(index);
3'd5: info_glyph=i5_glyph(index);
default: info_glyph=0; endcase end endfunction

// ---- mode label: 2 modes only (uses existing glyphs) ----
// glyph ids: 18,3 = raw ; 5,6 = dehaze ; 10,11 = detection
function [6:0] mode_glyph; input md; input [5:0] index; begin
 case(md)
  1'b0: begin case(index)                       // raw + detection
   6'd0: mode_glyph=7'd18; 6'd1: mode_glyph=7'd3;
   6'd2: mode_glyph=7'd10; 6'd3: mode_glyph=7'd11;
   default: mode_glyph=0; endcase end
  default: begin case(index)                    // dehaze + detection
   6'd0: mode_glyph=7'd5; 6'd1: mode_glyph=7'd6;
   6'd2: mode_glyph=7'd10; 6'd3: mode_glyph=7'd11;
   default: mode_glyph=0; endcase end
 endcase end endfunction
localparam integer MODE_LENGTH=4;

// ---- digits 0-9 live at glyph 87..96 (added into osd_font.hex) ----
function [6:0] digit_glyph; input [3:0] d; begin
 case(d)
  4'd0: digit_glyph=7'd87; 4'd1: digit_glyph=7'd88;
  4'd2: digit_glyph=7'd89; 4'd3: digit_glyph=7'd90;
  4'd4: digit_glyph=7'd91; 4'd5: digit_glyph=7'd92;
  4'd6: digit_glyph=7'd93; 4'd7: digit_glyph=7'd94;
  4'd8: digit_glyph=7'd95; 4'd9: digit_glyph=7'd96;
  default: digit_glyph=7'd0;
 endcase end endfunction
localparam integer SCORE_LENGTH=2;

function [6:0] manual_glyph;input [5:0] index;begin case(index)
6'd0:manual_glyph=7'd97;
6'd1:manual_glyph=7'd98;
6'd2:manual_glyph=7'd54;
6'd3:manual_glyph=7'd55;
default:manual_glyph=0;endcase end endfunction

function [6:0] help_glyph;input [5:0] index;begin case(index)
6'd0:help_glyph=7'd100;
6'd1:help_glyph=7'd101;
6'd2:help_glyph=7'd102;
6'd3:help_glyph=7'd103;
6'd4:help_glyph=7'd0;
6'd5:help_glyph=7'd104;
6'd6:help_glyph=7'd101;
6'd7:help_glyph=7'd54;
6'd8:help_glyph=7'd55;
6'd9:help_glyph=7'd0;
6'd10:help_glyph=7'd105;
6'd11:help_glyph=7'd106;
6'd12:help_glyph=7'd107;
6'd13:help_glyph=7'd108;
default:help_glyph=0;endcase end endfunction

function [6:0] counter_glyph;input [5:0] index;begin case(index)
6'd0:counter_glyph=7'd54;
6'd1:counter_glyph=7'd55;
default:counter_glyph=0;endcase end endfunction

function [6:0] ready_glyph;input [5:0] index;begin case(index)
6'd0:ready_glyph=7'd26;
6'd1:ready_glyph=7'd109;
6'd2:ready_glyph=7'd22;
6'd3:ready_glyph=7'd23;
default:ready_glyph=0;endcase end endfunction

function [6:0] waiting_glyph;input [5:0] index;begin case(index)
6'd0:waiting_glyph=7'd56;
6'd1:waiting_glyph=7'd57;
6'd2:waiting_glyph=7'd22;
6'd3:waiting_glyph=7'd23;
default:waiting_glyph=0;endcase end endfunction

function [6:0] mod0_glyph;input [5:0] index;begin case(index)
6'd0:mod0_glyph=7'd18;
6'd1:mod0_glyph=7'd3;
6'd2:mod0_glyph=7'd110;
6'd3:mod0_glyph=7'd43;
default:mod0_glyph=0;endcase end endfunction

function [6:0] mod1_glyph;input [5:0] index;begin case(index)
6'd0:mod1_glyph=7'd24;
6'd1:mod1_glyph=7'd25;
6'd2:mod1_glyph=7'd110;
6'd3:mod1_glyph=7'd43;
default:mod1_glyph=0;endcase end endfunction
