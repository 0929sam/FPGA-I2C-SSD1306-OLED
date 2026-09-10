module DIV_CLK(iRST,
					iCLK,
					oCLK_us
					);
					
input iRST,iCLK;
output reg oCLK_us;
parameter DIV_CNT_us = 10000000;

reg [31:0] div;

always @(posedge iCLK or posedge iRST)
	if(iRST == 1'd1)
		begin
			oCLK_us <= 1'd0;
			div  <= 32'd0;
		end
	else
		begin
			if( div == DIV_CNT_us)
				begin
					oCLK_us <= ~oCLK_us;
					div  <= 32'd0;
				end
			else
				begin
					div  <= div + 32'd1;
				end
		end
		
endmodule