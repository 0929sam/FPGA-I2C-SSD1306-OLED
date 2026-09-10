`timescale 1ns / 1ps

module master(
    // --- 腳位列表 ---
    iCLK, iRST, 
    SDA, SCL, isILDE, 
    start_button, stop_button
);

    // --- 腳位宣告 ---
    input  iCLK, iRST, start_button, stop_button;
    inout  SDA;
    output SCL, isILDE;
    
    // --- 參數 ---
    parameter DIV_CNT_us = 250;

    // --- 內部 wire 宣告 ---
    wire oCLK_us_w;
    wire debounced_start_level, debounced_stop_level;
    wire synced_start_level,    synced_stop_level;
    wire SDA_EN;
    wire i_SDA, o_SDA;

    //======================================================================
    // 步驟一：在高速 iCLK 時脈域下，對按鈕進行去彈跳
    //======================================================================
    debounce_sync #(
        .CLK_FREQ_HZ(50_000_000) // <<<--- 注意！請務必確認這是你板子的 iCLK 頻率
    ) start_button_filter (
        .iCLK(iCLK),
        .iRST(iRST),
        .i_async_button(start_button),
        .o_button_state(debounced_start_level) // 輸出穩定的按鈕狀態 (按下為0)
    );

    // (stop_button 的處理，原理相同，但我們先專注解決 start)
    debounce_sync #(.CLK_FREQ_HZ(50_000_000)) stop_button_filter (
        .iCLK(iCLK),
        .iRST(iRST),
        .i_async_button(stop_button),
        .o_button_state(debounced_stop_level)
    );

    //======================================================================
    // 步驟二：將按鈕狀態從高速 iCLK 域，安全地同步到慢速 iCLK_us 域
    //======================================================================
    // --- 時脈分頻模組 ---
    DIV_CLK#(.DIV_CNT_us(DIV_CNT_us))
    div_clk(
        .iRST(iRST), 
        .iCLK(iCLK), 
        .oCLK_us(oCLK_us_w)
    );

    // --- 跨時脈域同步模組 ---
    synchronizer start_level_sync (
        .iCLK(oCLK_us_w),      // 使用慢速的 iCLK_us 作為目標時脈
        .iRST(iRST),
        .i_async_data(debounced_start_level), // 輸入來自 iCLK 域的訊號
        .o_sync_data(synced_start_level)      // 輸出已同步到 iCLK_us 域的訊號
    );
    
    synchronizer stop_level_sync (
        .iCLK(oCLK_us_w),
        .iRST(iRST),
        .i_async_data(debounced_stop_level),
        .o_sync_data(synced_stop_level)
    );
    
    //======================================================================
    // 步驟三：在慢速 iCLK_us 域下，使用乾淨、同步的訊號
    //======================================================================
    // --- SDA 三態緩衝器 ---
    assign SDA = SDA_EN ? o_SDA : 1'bz;
    assign i_SDA = SDA_EN ? 1'b1 : SDA;

    // --- I2C 核心邏輯模組 ---
    IO_test io(
        .i_SDA(i_SDA),
        .o_SDA(o_SDA),
        .rst(iRST),
        .iCLK(iCLK),
        .iCLK_us(oCLK_us_w),
        .SCL(SCL),
        .SDA_EN(SDA_EN),
        .isILDE(isILDE),
        .start_button(debounced_start_level), // <<--- 使用最終處理過的乾淨訊號
        .stop_button(synced_stop_level)
    );

endmodule