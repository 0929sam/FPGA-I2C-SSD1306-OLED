`timescale 1ns / 1ps

module synchronizer_tb;

    // === 測試參數 ===
    parameter CLK_PERIOD_NS = 20; // 相當於 50MHz 時脈

    // === 測試用訊號 ===
    reg iCLK = 0;
    reg iRST = 1;
    reg i_async_data = 1; // 初始高
    wire o_sync_data;

    // === 例化待測模組 ===
    synchronizer uut (
        .iCLK(iCLK),
        .iRST(iRST),
        .i_async_data(i_async_data),
        .o_sync_data(o_sync_data)
    );

    // === 時脈產生器 ===
    always #(CLK_PERIOD_NS / 2) iCLK = ~iCLK;

    // === 測試流程 ===
    initial begin
        $display("Time\tRST\tin_async\tout_sync");
        $monitor("%t\t%b\t%b\t\t%b", $time, iRST, i_async_data, o_sync_data);

        // 初始重置
        #100;
        iRST = 0;

        // 模擬非同步訊號改變（類似另一個時脈域的邊緣）
        #75  i_async_data = 0; // 中間時間點改變，可能造成 metastability
        #100 i_async_data = 1;
        #65  i_async_data = 0;
        #250 i_async_data = 1;

        // 等待更多時脈週期觀察同步器輸出
        #500;

        $finish;
    end

endmodule
