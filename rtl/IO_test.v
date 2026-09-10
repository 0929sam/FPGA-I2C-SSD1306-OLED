`timescale 1ns / 1ps

module IO_test(
    // --- 腳位列表 ---
    i_SDA, o_SDA, rst, iCLK, iCLK_us, 
    SCL, SDA_EN, isILDE, 
    start_button, stop_button, 
    oLED
);
	 
	 parameter cmd_count = 40;
	 parameter data_count = 1023;

    // --- 腳位宣告 ---
    input       iCLK_us;
    input       iCLK;
    input       i_SDA;
    input       rst;
    input       start_button;
    input       stop_button;
    output reg  SCL;
    output reg  SDA_EN;
    output reg  isILDE;
    output reg  o_SDA;
    output      oLED; // 宣告一個 LED 輸出

    //======================================================================
    // 內部訊號宣告 (Internal Signals)
    //======================================================================

    // --- 狀態機定義 ---
    reg [3:0] state, next_state;
    localparam  IDLE    = 4'd0,
                STOP    = 4'd1,
                START   = 4'd2,
                CALL    = 4'd3,
                CONTROL = 4'd4,
                DATA    = 4'd5;

    // --- ROM 相關訊號 ---
    reg [11:0]  data_addr;
    wire [7:0]  data_data;
    reg         ready_data;
    reg [5:0]   cmd_addr;
    wire [7:0]  cmd_data;
    reg         rom_finished;

    // --- I2C 核心邏輯訊號 ---
    reg [7:0]   count;
    reg [3:0]   bit_counter;
    reg [7:0]   shift_reg;
    reg [7:0]   slave_addr;
    reg         ack_received;

    //======================================================================
    // 子模組實例化 (Module Instantiation)
    //======================================================================

    sync_rom u2(.clk(iCLK), .addr(data_addr), .data(data_data));
    ROM_cmd u1(.clk(iCLK), .addr(cmd_addr), .data(cmd_data));

    //======================================================================
    // 初始區塊 (Initial Block)
    //======================================================================

    initial begin
        slave_addr = 8'h78; // SSD1306 I2C 地址
    end
    
    //======================================================================
    // 時序邏輯 (Sequential Logic)
    //======================================================================

    // 狀態機暫存器
    always @(posedge iCLK_us or posedge rst) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    // 主要數據處理和輸出邏輯
    always @(posedge iCLK_us or posedge rst) begin
        if (rst) begin
            count        <= 7'd0;
            bit_counter  <= 4'd0;
            shift_reg    <= 8'h78;
            o_SDA        <= 1'dz;
            isILDE       <= 1'd1;
            ack_received <= 1'd0;
            cmd_addr     <= 6'd0;
            data_addr    <= 11'd0;
            rom_finished <= 1'b0;
            ready_data   <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    o_SDA        <= 1'dz;
                    isILDE       <= 1'd1;
                    count        <= 7'd0;
                    bit_counter  <= 4'd0;
                    ack_received <= 1'd0;
                    //cmd_addr     <= 6'd0;
                    //data_addr    <= 11'd0;
                    //rom_finished <= 1'b0;
						  if (count < 7'd3) 
                        count <= count + 1'd1;
							else 
                        count <= 7'd0;                       
                    
                end

                START: begin
                    isILDE <= 1'd0;
                    if (count < 7'd3) begin
                        o_SDA <= 1'd0; // START條件：SCL高時SDA下降沿
                        count <= count + 1'd1;
                    end else begin
                        count <= 7'd0;
                        bit_counter <= 4'd0; // 準備開始位傳輸
                    end
                end

                STOP: begin
                    isILDE <= 1'd0;
						  if(count < 7'd3)begin
								o_SDA <= 1'd0;
								count <= count + 1'd1;
                    end else if( count == 7'd3 || count == 7'd4)
								count <= count + 1'd1;
						  else if( count == 7'd5) begin
                        o_SDA <= 1'dz; // STOP條件：SCL高時SDA上升沿
                        count <= count + 1'd1;
                    end else begin
                        count <= 7'd0;
								bit_counter <= 4'd0;
                    end
                end

                CALL: begin // 發送從機地址
                    isILDE <= 1'd0;
                    /*if (bit_counter == 4'd0)
                        shift_reg <= slave_addr;*/

                    if (bit_counter < 4'd9) begin
                        if (count == 7'd0) begin
                            if (bit_counter < 4'd8)
                                o_SDA <= (shift_reg[7])? 1'dz:1'd0;
                            count <= count + 1'd1;
                        end else if (count == 7'd1) begin
                            count <= count + 1'd1;
                        end else if (count == 7'd2) begin
                            if (bit_counter == 4'd8)begin
                                ack_received <= ~i_SDA;
										  o_SDA <= 1'd0;
									 end
                            count <= count + 1'd1;
                        end else begin // count == 3
                            if (bit_counter < 4'd8)
                                shift_reg <= {shift_reg[6:0], 1'b0};
                            count <= 7'd0;
                            bit_counter <= bit_counter + 1'd1;
                        end
								
								if(bit_counter == 4'd8 && count == 8'd3)begin
									bit_counter <= 4'd0;
									shift_reg <= (ready_data)? 8'b0100_0000 : 8'b0000_0000;//-----------------------------
								end
																								
                    end 
						  
						  
                end

                CONTROL: begin // 發送控制字元
                    isILDE <= 1'd0;
						  /*if (bit_counter == 4'd0)
							   shift_reg <= (ready_data)? 8'b0100_0000 : 8'b0000_0000;*/
						  
                    if (bit_counter < 4'd9) begin
                        if (count == 7'd0) begin                            
                            if (bit_counter < 4'd8)
                                o_SDA <= (shift_reg[7])? 1'dz:1'd0;
                            count <= count + 1'd1;
                        end else if (count == 7'd1) begin
                            count <= count + 1'd1;
                        end else if (count == 7'd2) begin
                            if (bit_counter == 4'd8)begin
                                ack_received <= ~i_SDA;
										  o_SDA <= 1'd0; 
									 end
                            count <= count + 1'd1;
                        end else begin // count == 3
                            if (bit_counter < 4'd8)
                                shift_reg <= {shift_reg[6:0], 1'b0};
                            count <= 7'd0;
                            bit_counter <= bit_counter + 1'd1;
                        end
								
								if(bit_counter == 4'd8 && count == 8'd3)begin
									bit_counter <= 4'd0;
									shift_reg <= (ready_data)? data_data : cmd_data;//---------------------------------
								end
								
                    end 
                end

                DATA: begin // 發送資料
                    isILDE <= 1'd0;
						  
						  /*if (bit_counter == 4'd0)
                        shift_reg <= (ready_data)? data_data : cmd_data;*/
                    if (bit_counter < 4'd9) begin
                        if (count == 7'd0) begin
                            
                            if (bit_counter < 4'd8)
                                o_SDA <= (shift_reg[7])? 1'dz:1'd0;
                            count <= count + 1'd1;
                        end else if (count == 7'd1) begin
                            count <= count + 1'd1;
                        end else if (count == 7'd2) begin
                            if (bit_counter == 4'd8)begin
                                ack_received <= ~i_SDA;
										  o_SDA <= 1'd0;
									 end
                            count <= count + 1'd1;
                        end else begin // count == 3
                            if (bit_counter < 4'd8)
                                shift_reg <= {shift_reg[6:0], 1'b0};
										  count <= 7'd0;
                                bit_counter <= bit_counter + 1'd1;
                        end
								
								if(bit_counter == 4'd8 && count == 8'd3)begin
									bit_counter <= 4'd0;
									shift_reg <= slave_addr;//----------------------------------
									
									if (ready_data) begin
                            if (data_addr == data_count) begin
                                ready_data <= 1'b0;
                            end else begin
                                data_addr <= data_addr + 1;
                            end
									end else begin
                            if (cmd_addr == cmd_count) begin
                                rom_finished <= 1'b1;
                                ready_data <= 1'b1;
                            end else begin
                                cmd_addr <= cmd_addr + 1;
                            end
									end
								end
								
                    end 
                end
            endcase
        end
    end

    //======================================================================
    // 組合邏輯 (Combinational Logic)
    //======================================================================

    // 狀態轉換邏輯
    always @(*) begin
        // 預設保持在目前狀態，避免產生 Latch
        case (state)
            IDLE: begin
                if ((~start_button | ready_data) && count == 8'd3)
                    next_state = START;
                else
                    next_state = IDLE;
            end
            STOP: begin
                if (count == 7'd5)
                    next_state = IDLE;
                else
                    next_state = STOP;
            end
            START: begin
                if (count == 7'd3)
                    next_state = CALL;
                else
                    next_state = START;
            end
            CALL:begin
                if (bit_counter == 4'd8 && count == 8'd3)
                    if (ack_received)
                        next_state = CONTROL;
                    else
                        next_state = STOP;
                else
                    next_state = CALL;
            end
            CONTROL: begin
                if (bit_counter == 4'd8 && count == 8'd3)
                    if (ack_received)
                        next_state = DATA;
                    else
                        next_state = STOP;
                else
                    next_state = CONTROL;
            end
            DATA: begin
                if (bit_counter == 4'd8 && count == 8'd3) begin
                    if (ack_received) begin
                        if (ready_data) begin
                            if (data_addr == data_count)
                                next_state = STOP;
                            else
                                next_state = STOP;
                        end else begin
                            if (cmd_addr == cmd_count)
                                next_state = STOP;
                            else
                                next_state = STOP;
                        end
                    end else begin
                        next_state = STOP;
                    end
                end else begin
                    next_state = DATA;
                end
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    // SDA_EN 控制邏輯             
    always @(*) begin
        if (bit_counter == 4'd8 ) // ACK位
            SDA_EN = 1'd0;
        else
            SDA_EN = 1'd1;
    end

    // SCL 控制邏輯
    always @(*) begin
        SCL = 1'b1; // 先給 SCL 一個明確的預設值
        if (state == CALL || state == CONTROL || state == DATA) begin
            if (count != 7'd3) 
                SCL = 1'b0;
        end
		  
		  if (state == STOP) begin
            if (count == 7'd0 || count == 7'd1 || count == 7'd2) 
                SCL = 1'b0;
        end
    end

endmodule