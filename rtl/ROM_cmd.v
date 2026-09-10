`timescale 1ns / 1ps

module ROM_cmd(clk, addr, data);
    input             clk;
    input      [5:0]  addr;
    output reg [7:0]  data;

    always @(posedge clk) begin
        case (addr)
            6'd0  : data = 8'hAE; // 1. Display OFF
            6'd1  : data = 8'h20; // 2. Memory Addressing Mode
            6'd2  : data = 8'h01; // 3. Vertical Addressing Mode
            6'd3  : data = 8'hB0; // 4. Set Page Start Address
            6'd4  : data = 8'hC8; // 5. COM Output Scan Direction
            6'd5  : data = 8'h00; // 6. Set Low Column Start Address
            6'd6  : data = 8'h20; // 7. Set High Column Start Address
            6'd7  : data = 8'h40; // 8. Set Start Line Address
            6'd8  : data = 8'h81; // 9. Set Contrast Control
            6'd9  : data = 8'hFF; // 10. Contrast Value
            6'd10 : data = 8'hA1; // 11. Segment Re-map
            6'd11 : data = 8'hA6; // 12. Normal Display
            6'd12 : data = 8'hA8; // 13. Set Multiplex Ratio
            6'd13 : data = 8'h3F; // 14. Multiplex Ratio Value (64)
            6'd14 : data = 8'hA4; // 15. Display All On Resume
            6'd15 : data = 8'hD3; // 16. Set Display Offset
            6'd16 : data = 8'h00; // 17. Display Offset Value
            6'd17 : data = 8'hD5; // 18. Set Display Clock Divide
            6'd18 : data = 8'hF0; // 19. Clock Divide Ratio
            6'd19 : data = 8'hD9; // 20. Set Pre-charge Period
            6'd20 : data = 8'h22; // 21. Pre-charge Period Value
            6'd21 : data = 8'hDA; // 22. Set COM Pins Config
            6'd22 : data = 8'h12; // 23. COM Pins Config Value
            6'd23 : data = 8'hDB; // 24. Set VCOMH Deselect Level
            6'd24 : data = 8'h30; // 25. VCOMH Deselect Level
            6'd25 : data = 8'h8D; // 26. Charge Pump Setting
            6'd26 : data = 8'h14; // 27. Enable Charge Pump
            6'd27 : data = 8'hAF; // 28. Display ON
            6'd28 : data = 8'h80; // 29. Set Column Address
            6'd29 : data = 8'h00; // 30. Column Start Address
            6'd30 : data = 8'h80; // 31. Set Column Address
            6'd31 : data = 8'h20; // 32. Column End Address
            6'd32 : data = 8'h80; // 33. Set Page Address
            6'd33 : data = 8'h40; // 34. Page Start Address
            6'd34 : data = 8'h20; // 35. Set Page Address
            6'd35 : data = 8'h01; // 36. Page End Address
            6'd36 : data = 8'h21; // 37. Set Column Address Command
            6'd37 : data = 8'h00; // 38. Column Start
            6'd38 : data = 8'h7F; // 39. Column End (127)
            6'd39 : data = 8'h40; // 40. Set Start Line
            6'd40 : data = 8'h00; // 41. Start Line Value (完成)
				
            default: data = 8'h00;
        endcase
    end
endmodule
