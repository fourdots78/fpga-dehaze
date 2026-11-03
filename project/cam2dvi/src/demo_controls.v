`default_nettype none
module demo_controls #(
 parameter integer DEBOUNCE=1048576, DOUBLE_GAP=22275000, LONG_HOLD=74250000
)(input wire clk,rst_n,key_n, output reg display_mode,
 output reg manual_capture,clear_capture);
reg [1:0] sync;reg stable;reg [26:0] debounce,held,gap;
reg long_sent,pending;
always @(posedge clk or negedge rst_n)begin
 if(!rst_n)begin sync<=3;stable<=1;debounce<=0;held<=0;gap<=0;long_sent<=0;pending<=0;display_mode<=1;manual_capture<=0;clear_capture<=0;end
 else begin
  sync<={sync[0],key_n};manual_capture<=0;clear_capture<=0;
  if(sync[1]!=stable)begin
   if(debounce==DEBOUNCE-1)begin
    stable<=sync[1];debounce<=0;
    if(!sync[1])begin held<=0;long_sent<=0;end
    else if(!long_sent)begin
     if(pending)begin manual_capture<=1;pending<=0;gap<=0;end
     else begin pending<=1;gap<=0;end
    end
   end else debounce<=debounce+1'b1;
  end else debounce<=0;
  if(!stable&&!long_sent)begin
   if(held==LONG_HOLD-1)begin clear_capture<=1;long_sent<=1;pending<=0;end
   else held<=held+1'b1;
  end
  // Pause the single-click deadline during a second press.
  if(pending&&stable&&sync[1]&&debounce==0)begin
   if(gap==DOUBLE_GAP-1)begin display_mode<=~display_mode;pending<=0;end
   else gap<=gap+1'b1;
  end
 end
end
endmodule
`default_nettype wire
