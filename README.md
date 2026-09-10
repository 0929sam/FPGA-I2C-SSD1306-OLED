# FPGA I2C Master — SSD1306 OLED Driver

![Platform](https://img.shields.io/badge/Platform-Cyclone%20V%20(5CSEMA4U23C6)-blue)
![Language](https://img.shields.io/badge/Language-Verilog%20HDL-informational)
![Toolchain](https://img.shields.io/badge/Toolchain-Intel%20Quartus%20Prime-orange)
![Protocol](https://img.shields.io/badge/Protocol-I2C%20(bit--banged)-brightgreen)

## 📌 專案簡介 (Overview)

從零手刻一個 **I2C Master 控制器**，不使用任何 IP 或現成 I2C 控制器 IP core，純用 Verilog
狀態機實作 START/STOP 條件、位元傳輸與 ACK 偵測，透過杜邦線接到 **SSD1306 0.96" OLED**
（I2C 位址 `0x78`），送出完整的初始化指令序列，再把一張 128×64 的點陣圖畫面傳輸上去顯示。

系統分成兩個時脈域：FPGA 端 50 MHz 高速時脈負責按鍵去彈跳，再分頻出約 100 kHz（I2C
Standard-mode 速度）的匯流排時脈驅動整個 I2C 狀態機，兩個時脈域之間用雙正反器同步器
（synchronizer）安全地跨時脈域傳遞按鍵訊號。

---

## 🏆 專案亮點

- 🔌 **純手刻 I2C Master**：不掛 IP，自己刻 START/STOP 條件、逐位元 shift、ACK 偵測與錯誤處理
- ⏱️ **雙時脈域設計**：50 MHz 去彈跳 + 分頻出 ~100 kHz I2C 時脈，中間用同步器安全跨時脈域
- 🧪 **模擬驗證優先**：`master_tb.v` 自己寫了一個假 I2C Slave，會在正確時機自動回 ACK，完整
  跑過「按鍵 → 送指令 → 送圖像資料」整個流程才上板測試
- 🔍 **SignalTap 實測時序**：直接在硬體上量測 START/STOP 條件的實際持續時間，抓出時序不符
  I2C 規範的問題
- 🐛 **完整除錯歷程**：從 6 月到 9 月，橫跨三個月的每週進度報告都留著，記錄了從「不知道有沒有
  收到 ACK」到「畫面出得來但不是預期畫面」的完整排查過程（詳見下方）

---

## 🐛 除錯歷程 (Debugging Journey)

這個專案前後花了將近三個月才成功點亮螢幕，過程中的每一次進度報告都整理如下——這是直接從
自己當時做的簡報內容整理過來的真實記錄，不是事後美化：

| 時間 | 遇到的問題 | 排查/解法 |
| :--- | :--- | :--- |
| 6/25 | 第一個 byte 收不到 | 把 `count` 多算一拍，讓 `shift_reg` 更新和 `o_SDA` 輸出錯開，不要在同一拍搶著動作 |
| 6/25 | 不確定 ACK 有沒有正確接收 | 確認 `ack_received` 為 1 才繼續下一步，為 0 就直接跳回 `STOP`，並逐筆核對 41 筆初始化指令的內容（例如第 10 筆 `6'd10 : data = 8'hA1`）是否正確 |
| 7/23 | 懷疑是按鍵彈跳造成誤判 start，或是 ACK 沒處理好導致讀不到 | 針對 debounce 與 ACK 時序寫出具體問題去請教學長 |
| 7/8 – 8/12 | **畫面能出來了，但不是預期的畫面**（推測即為下方 demo 影片中「整片點亮」的狀況）| 一度以為是初始化指令不適合這塊板子、或訊號沒送出去，找了快一個月都沒有頭緒 |
| 8/18 – 9/3 | 在學長協助下，用 SignalTap 實測 START / STOP 條件的實際持續時間（量到約 **1560 ns**），對照 I2C 規範，抓出時序不合規的問題並修正 | 修正後終於成功穩定顯示畫面 |

> 📎 影片裡「整片全亮」的畫面，很可能就是上表「畫面能出來但不是預期畫面」那個卡了快一個月的問題——
> 簡報裡沒有明確寫「全亮」這個字眼，是我從問題描述比對推測的，實際症狀以影片為準。

---

## ⚙️ 規格摘要 (Key Specifications)

| 項目 | 內容 |
| :--- | :--- |
| **開發板 (Board)** | Cyclone V FPGA 開發板，`5CSEMA4U23C6` |
| **顯示器** | SSD1306 0.96" OLED（128×64，單色，I2C 位址 `0x78`） |
| **語言 / 工具鏈** | Verilog HDL / Intel Quartus Prime |
| **連接方式** | 杜邦線：SCL → GPIO_1[0]、SDA → GPIO_1[1] |
| **時脈系統** | 50 MHz 輸入 → `DIV_CLK` 分頻 → 約 100 kHz（I2C Standard-mode）匯流排時脈 |
| **I2C 狀態機** | IDLE → START → CALL（位址）→ CONTROL（控制位元組）→ DATA → STOP |
| **初始化指令** | 41 筆 SSD1306 設定指令（`ROM_cmd.v`），涵蓋定址模式、掃描方向、對比度、充電幫浦等 |
| **顯示內容** | 128×64 點陣圖（`sync_rom.v`，1024 bytes） |
| **除錯方式** | 內嵌 SignalTap 邏輯分析儀，實測 START/STOP 條件時序 |

---

## 🏛️ 系統架構 (System Architecture)

```mermaid
flowchart TB
    subgraph S1[" 按鍵輸入 → 去彈跳 → 跨時脈域同步 "]
        direction LR
        BTN(["start_button\nstop_button"]) --> DB[debounce_sync ×2\n20ms 去彈跳]
        DB --> SYNC[synchronizer ×2\n2級正反器 CDC]
    end

    CLK(["iCLK\n50MHz"]) --> DIV[DIV_CLK\n分頻器]
    DIV --> CLKUS(["oCLK_us\n約100kHz I2C 匯流排時脈"])

    CLKUS --> FSM[IO_test\nI2C Master FSM\nIDLE→START→CALL→CONTROL→DATA→STOP]
    SYNC -- synced_start / synced_stop --> FSM

    ROMCMD[("ROM_cmd\n41 筆 SSD1306 初始化指令")]
    ROMPIX[("sync_rom\n1024 bytes\n128×64 點陣圖")]
    FSM <--> ROMCMD
    FSM <--> ROMPIX

    FSM -- SDA_EN / o_SDA --> TRI{{"master.v\nSDA 三態緩衝器"}}
    TRI --> BUS(["SCL / SDA\n杜邦線"])
    BUS --> OLED(["SSD1306 OLED\nI2C 位址 0x78"])
```

### 模組說明 (Module Breakdown)

| 檔案 | 說明 |
| :--- | :--- |
| [`master.v`](rtl/master.v) | 頂層模組：整合去彈跳、分頻、同步器與 I2C 引擎，並實作 SDA 三態緩衝器 |
| [`IO_test.v`](rtl/IO_test.v) | I2C 核心狀態機：START/STOP 條件產生、逐位元傳輸、ACK 偵測，依序送出初始化指令與圖像資料 |
| [`DIV_CLK.v`](rtl/DIV_CLK.v) | 時脈分頻器：50 MHz → 約 100 kHz，供 I2C 狀態機使用 |
| [`synchronizer.v`](rtl/synchronizer.v) | 通用 2 級正反器同步器，處理跨時脈域訊號 |
| [`debounce_sync.v`](rtl/debounce_sync.v) | 按鍵去彈跳（20ms），含同步器降低亞穩態 |
| [`ROM_cmd.v`](rtl/ROM_cmd.v) | SSD1306 初始化指令 ROM（41 筆，逐筆註解說明每個指令的作用） |
| [`sync_rom.v`](rtl/sync_rom.v) | 128×64 點陣圖畫面資料 ROM（1024 bytes） |

### 測試平台 (Testbenches)

| 檔案 | 說明 |
| :--- | :--- |
| [`master_tb.v`](rtl/master_tb.v) | 系統級模擬：自己寫了一個會依時機自動回 ACK 的假 I2C Slave，完整跑過「按鍵觸發 → 送指令 → 送圖像」流程 |
| [`IO_test_tb.v`](rtl/IO_test_tb.v) | 針對 I2C 核心狀態機的單元測試 |
| [`synchronizer_tb.v`](rtl/synchronizer_tb.v) | 同步器單元測試 |
| [`debounce_sync_tb.v`](rtl/debounce_sync_tb.v) | 去彈跳模組單元測試 |

---

## 📹 實機照片與影片

- [docs/media/IMG_1356.HEIC](docs/media/IMG_1356.HEIC)（板子與 OLED 接線實拍照，iPhone HEIC 格式，多數瀏覽器無法直接預覽）
- [docs/media/IMG_1903.MOV](docs/media/IMG_1903.MOV)
- [docs/media/IMG_1982.MOV](docs/media/IMG_1982.MOV)

> 兩支影片其中一支是除錯過程中「畫面不符預期」的實拍紀錄，另一支是最終成功顯示畫面的版本——
> 我這邊無法直接播放影片確認是哪一支對應哪一支，先都列在這裡，之後我們可以幫忙補上標註。

---

## 🔧 如何開啟專案 (How to Open in Quartus)

1. 安裝 [Intel Quartus Prime](https://www.intel.com/content/www/us/en/software-kit/programmable/quartus-prime/prime-lite.html)（Lite 版即可，需支援 Cyclone V）
2. `File` → `Open Project` → 選擇 `rtl/lab4.qpf`
3. `Processing` → `Start Compilation` 進行合成與燒錄檔產生
4. 透過 USB-Blaster 燒錄至開發板，並依規格表的腳位接上 SSD1306（SCL/SDA/GND/VCC）

---

## 📂 專案結構 (Repository Structure)

```
FPGA-I2C-SSD1306-OLED/
├── rtl/                       # 手刻 Verilog 原始碼 + 測試平台 + Quartus 專案檔
│   ├── master.v               (頂層)
│   ├── IO_test.v               (I2C 核心狀態機)
│   ├── DIV_CLK.v
│   ├── synchronizer.v
│   ├── debounce_sync.v
│   ├── ROM_cmd.v
│   ├── sync_rom.v
│   ├── master_tb.v / IO_test_tb.v / synchronizer_tb.v / debounce_sync_tb.v
│   └── lab4.qpf / lab4.qsf
├── docs/
│   └── media/                 # 實機照片與 Demo 影片
└── README.md
```

---

## 👤 作者 (Author)

**CHEN SHUO HU**

RTL、I2C 狀態機設計與除錯皆為個人獨立完成。
