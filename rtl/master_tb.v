`timescale 1ns/1ps

module master_tb;

    // --- 宣告 ---
    reg iCLK, iRST, start_button, stop_button;
    wire SDA, SCL, isILDE;
    
    // --- ACK 要素 1: 模擬 Slave 的輸出 ---
    // 這個 reg 代表 Slave (OLED) 何時要控制 SDA 線
    reg i_SDA_slave_ack;

    // --- 實例化 DUT (Design Under Test) ---
    master u1(
        .iCLK(iCLK), 
        .iRST(iRST), 
        .SDA(SDA), 
        .SCL(SCL), 
        .isILDE(isILDE), 
        .start_button(start_button), 
        .stop_button(stop_button)
    );
    
    // --- 加速模擬 ---
    defparam u1.div_clk.DIV_CNT_us = 25; 

    // --- 階層式訊號存取 (方便觀察) ---
	 wire       o_SDA        = u1.io.o_SDA;
	 wire       iCLK_us      = u1.div_clk.oCLK_us;
    wire [3:0] state        = u1.io.state;
	 wire [7:0] count        = u1.io.count;
	 wire [3:0] bit_counter  = u1.io.bit_counter;
	 //wire [1:0] type         = u1.io.type;
    wire [5:0] cmd_addr     = u1.io.cmd_addr;
    wire [7:0] cmd_data     = u1.io.cmd_data;
    wire [11:0] data_addr   = u1.io.data_addr;
    wire [7:0] data_data    = u1.io.data_data;
	 wire [7:0] shift_reg    = u1.io.shift_reg;
    wire       SDA_EN       = u1.io.SDA_EN;
    wire       ack_received = u1.io.ack_received;

    // --- ACK 要素 2: 模擬共享匯流排 ---
    // 當 SDA_EN 為 1, Master 控制 SDA; 當 SDA_EN 為 0, Slave (我們的 testbench) 控制 SDA
    assign SDA = (SDA_EN == 1'b1) ? u1.io.o_SDA : i_SDA_slave_ack;

    // --- 時脈產生 ---
    initial begin
        iCLK = 0;
        forever #5 iCLK = ~iCLK; // 100MHz clock
    end
    
    // --- 測試序列 ---
    initial begin
        
        // 1. 初始化
        iRST = 1'b1;
        start_button = 1'b1; // 初始未按下 (active low)
        i_SDA_slave_ack = 1'bz; // Slave 初始為高阻態
        #20;
        iRST = 1'b0;
        #1000;

        // 2. 第一次按鈕: 發送初始化指令
        $display("--> First press: Sending CMDs at time %t...", $time);
        start_button = 1'b0;
        #30_000_000; // 保持按下狀態 30ms
        start_button = 1'b1;
        
        #1_000_000; // 等待指令傳輸完成

        // 3. 第二次按鈕: 發送圖像資料
        $display("--> Second press: Sending DATA at time %t...", $time);
        start_button = 1'b0;
        #15_000_000; // 保持按下狀態 30ms
        start_button = 1'b1;

        #40_000_000; // 讓資料傳輸有足夠的時間跑
        
        $display("--> Test finished at time %t", $time);
        $finish;
    end

    // --- ACK 要素 3: 控制 ACK 時機 ---
    // 在 SCL 下降緣時檢查 Master 是否在等待 ACK
    always @(negedge SDA_EN) begin
        if (SDA_EN == 1'b0) begin // 如果 Master 釋放了 SDA 線...
            i_SDA_slave_ack <= 1'b0; // ...Slave (testbench) 就把 SDA 拉低來發送 ACK
        end
    end
    
    // 在 SCL 上升緣後釋放 ACK
    always @(posedge SDA_EN) begin
        if (i_SDA_slave_ack == 1'b0) begin
            i_SDA_slave_ack <= 1'bz; // ACK 只需維持到 SCL 變高後，即可釋放
        end
    end

endmodule