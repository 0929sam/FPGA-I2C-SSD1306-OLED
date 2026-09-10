`timescale 1ns / 1ps

// 通用訊號同步器
module synchronizer (
    input       iCLK,         // 目標時脈域 (我們將會接 iCLK_us)
    input       iRST,         // 目標時脈域的重置
    input       i_async_data, // 來自其他時脈域的非同步資料
    output      o_sync_data   // 同步後的輸出資料
);
    // 兩級正反器來降低亞穩態機率
    reg r_ff1, r_ff2;

    always @(posedge iCLK or posedge iRST) begin
        if (iRST) begin
            r_ff1 <= 1'b1; // 預設為高電位
            r_ff2 <= 1'b1;
        end else begin
            r_ff1 <= i_async_data;
            r_ff2 <= r_ff1;
        end
    end

    assign o_sync_data = r_ff2;
endmodule