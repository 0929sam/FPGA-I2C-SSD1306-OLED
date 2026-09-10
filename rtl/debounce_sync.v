`timescale 1ns / 1ps

module debounce_sync #(
    parameter CLK_FREQ_HZ = 50_000_000, 
    parameter DEBOUNCE_MS = 20         
) (
    input               iCLK,
    input               iRST,
    input               i_async_button,
    output              o_button_state
);

    localparam DEBOUNCE_CLOCKS = (CLK_FREQ_HZ / 1000) * DEBOUNCE_MS;

    reg [2:0]   sync_ff;
    reg [31:0]  debounce_counter;
    reg         button_state_reg;

    assign o_button_state = button_state_reg;

    always @(posedge iCLK or posedge iRST) begin
        if (iRST) begin
            sync_ff <= 3'b111;
        end else begin
            sync_ff <= {sync_ff[1:0], i_async_button};
        end
    end

    always @(posedge iCLK or posedge iRST) begin
        if (iRST) begin
            debounce_counter <= 0;
            button_state_reg <= 1'b1;
        end else begin
            if (sync_ff[2] == button_state_reg) begin
                debounce_counter <= 0;
            end else begin
                if (debounce_counter < DEBOUNCE_CLOCKS - 1) begin
                    debounce_counter <= debounce_counter + 1;
                end else begin
                    button_state_reg <= sync_ff[2];
                end
            end
        end
    end

endmodule