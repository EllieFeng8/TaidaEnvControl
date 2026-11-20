# 台達西側治具 QML 畫面

以參考圖片的 1100 × 770 為基準，視窗縮放時等比例置中顯示。
在 Qt Design Studio 開啟 `TaidaEnvControl.qmlproject` 查看畫面；完整操作請建置並執行 C++ 應用程式，由 `App/main.cpp` 注入 `TC` proxy。單獨以 qml 執行器執行 `App.qml` 不會建立 C++ proxy。

## 檔案配置

- `TaidaEnvControlContent/Screen01.ui.qml`：設計工具入口。
- `TaidaEnvControlContent/Dashboard.qml`：畫面排列與對外資料介面。
- `TaidaEnvControlContent/modules/`：標題、急停、重置、閥門、溫度、漏水監控，各自獨立成檔；兩個閥門共用 `ValvePanel`，兩個溫度區塊共用 `TemperaturePanel`。
- `TaidaEnvControlContent/components/`：配色、面板、指示燈、讀值、開關、設定輸入、漏水狀態等共用元件。

## 操作與設備串接

所有數字（閥門讀值、溫度與設定值）預設為 0，顯示為 `0.0`，尚未連接實體設備。

`Core/TaidaEnvControlProxy.h` 是所有數值與狀態的資料入口，QML 統一使用 `TC.`。C++ 的讀取函式為 `get...`、寫入函式為 `set...`，值改變時發出 `...Changed`。

| QML 屬性／方法 | 用途 |
| --- | --- |
| `TC.outPv`、`TC.inPv` | 出／入水閥目前開度（%） |
| `TC.outSv`、`TC.inSv` | 出／入水閥設定開度（0–100%，一位小數） |
| `TC.temp1`、`TC.temp2` | 兩組溫度（°C） |
| `TC.emergency` | 緊急開關，true 為啟動 |
| `TC.leak1`、`TC.leak2`、`TC.leak3` | 機房、管路、閥箱漏水，true 為漏水 |
| `TC.setReset()` | 將兩個 SV 歸零並發出 `resetRequested()` |

例如 QML 使用 `value: TC.outPv` 讀值、`TC.outSv = 35.5` 寫入設定值；C++ 使用 `proxy.setTemp1(25.6)` 回報溫度。數值 setter 拒絕 NaN／Infinity，SV 另拒絕超出範圍的值並四捨五入至一位小數。三個漏水狀態初始皆為 false，須由設備回報更新。

`Dashboard` 原有資料名稱保留為唯讀檢視，更新資料請改用 `TC`。

SV 接受 0–100，最多一位小數；按 Enter 或 SET 套用。操作會發出 `outletSetpointRequested(value)` 或 `inletSetpointRequested(value)` 訊號。

設定值取得焦點時會全選；按 Enter 或 SET 套用後清除焦點與選取狀態。

急停啟用時，面板紅色外框會以兩秒為一週期呼吸明暗變化；兩個 SV 輸入框與 SET 按鈕變暗並禁用，同時清除焦點及未套用的輸入，保留已套用的設定值。關閉急停後恢復操作。

急停開關會更新示範狀態並發出 `emergencyRequested(engaged)`，啟用時顯示加粗紅色狀態框與開關外框。RESET 會開啟重啟確認對話框，按「確認重啟」會將兩個閥門設定值及未套用的輸入歸零，再發出 `resetRequested()`；取消或 Escape 會保留設定且不送出請求。實際重啟由設備後端執行，不會自行清除漏水警報。

## 驗證

以 CMake 設定 `-DTAIDA_BUILD_TESTS=ON` 後建置 `TaidaEnvControlTests`，再執行 `ctest --test-dir <建置目錄> --output-on-failure`。測試透過與正式程式相同的 C++ proxy 驗證 QML 綁定、數值檢核、急停、三個漏水狀態及重置流程。
