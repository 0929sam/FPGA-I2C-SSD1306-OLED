`timescale 1ns / 1ps

module debounce_sync_tb;

    // === 參數 ===
    parameter CLK_FREQ_HZ = 50_000_000;
    parameter DEBOUNCE_MS = 20;
    localparam CLK_PERIOD_NS = 1_000_000_000 / CLK_FREQ_HZ;

    // === 測試用訊號 ===
    reg iCLK = 0;
    reg iRST = 1;
    reg i_async_button = 1; // 預設未按下（高電位）
    wire o_button_state;

    // === 實例化待測模組 ===
    debounce_sync #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .DEBOUNCE_MS(DEBOUNCE_MS)
    ) uut (
        .iCLK(iCLK),
        .iRST(iRST),
        .i_async_button(i_async_button),
        .o_button_state(o_button_state)
    );

    // === 時脈產生器 ===
    always #(CLK_PERIOD_NS/2) iCLK = ~iCLK;

    // === 測試刺激 ===
    initial begin
        $display("Time\tRST\tin_btn\tout_btn");

        $monitor("%t\t%b\t%b\t%b", $time, iRST, i_async_button, o_button_state);

        // 重置信號
        #100;
        iRST = 0;

        // 模擬有 bouncing 的按下動作（抖動）
        #100_000; i_async_button = 0;
        #1_000;   i_async_button = 1;
        #1_000;   i_async_button = 0;
        #500;     i_async_button = 1;
        #500;     i_async_button = 0; // 最後穩定為 0

        // 等待 debounce 生效
        #(DEBOUNCE_MS * 1_000_000); // 換算成 ns

        // 模擬有 bouncing 的釋放動作（抖動）
        #100_000; i_async_button = 1;
        #1_000;   i_async_button = 0;
        #1_000;   i_async_button = 1;
        #500;     i_async_button = 0;
        #500;     i_async_button = 1; // 最後穩定為 1

        // 等待 debounce 生效
        #(DEBOUNCE_MS * 1_000_000);

        // 結束模擬
        #100_000;
        $finish;
    end

endmodule
