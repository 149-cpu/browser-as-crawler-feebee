# 飛比購物幫手（feebee shopping helper）v3.55.0 — 技術拆解

飛比購物幫手是一支台灣的購物比價 Chrome 擴充。拆開它的程式碼，它做的不只比價：用你的登入身分就地採集電商賣家資料、把你點「關閉」比價視窗變成一次聯盟佣金歸因、把你逛過的每一頁回傳伺服器。以下每項都對到擴充自身 v3.55.0 的程式碼、可自行複現，不含詮釋。

## 30 秒自己看
裝了飛比的話：購物商品頁開 `F12` → Network，點比價浮窗的「×」關閉——若冒出一筆跳向 `feebee.com.tw/rd/…` 的請求，那一下「關閉」就是一次聯盟歸因寫入（見[發現 2](findings/02-affiliate-hijacking.md)）。

## 標的與完整性
- Chrome Web Store ID：`lmldjiibpfhdjjdjapcdlpjgeaihflpi`，版本 `3.55.0`。
- 線上重抓 CRX：190,901 bytes，`Cr24` 簽章，SHA-256 `a3dbe9210f9a12f2e6ec4b199dfecce1afab5c77176237cc3fabe7f8c4fc42ba`。
- 該版**簽章＋雜湊雙鎖**，此處引用的程式碼可被任何人重抓、逐位元驗證（見 [REPRODUCE.md](REPRODUCE.md)）。
- manifest：MV3；`content_scripts` 之 `ec.min.js`+`traffic.min.js` 配 `http(s)://*/*`；`externally_connectable.matches = ["*://*.feebee.com.tw/*"]`；`host_permissions = ["*://*.feebee.com.tw/*"]`。
- 行號基準：對 `3.55.0` 以 `js-beautify` 反混淆後之結果。

## 證據等級
| 標籤 | 意思 |
|---|---|
| `已捕獲` | 實際在公開端點回應中觀測到、現在就能重現 |
| `程式碼具備·可遠端開` | 程式碼有、旗標在伺服器、本次擷取未見啟用 |
| `外部` | 由擴充程式碼以外的證據支持（如 HTTP 標頭） |

## 發現
每項一句話帶過，點狀態標籤讀帶行號證據的全文。

**🕸️ 0. 借 session 分散式採集**
把安裝用戶群變成分散式爬蟲——讀你已登入開啟的頁面、在你的身分下回傳，不碰平台 API，難歸因難封鎖。
[`已捕獲` →](findings/00-distributed-scraping.md)

**👻 1. 任意 URL 隱形載入**
背景可在隱藏分頁載入任意 URL、載完即關——用你的 IP＋cookie 對「任何東西」發請求的通用原語。
[`程式碼具備·可遠端開` →](findings/01-hidden-background-tab.md)

**💰 2. 聯盟歸因劫持 / cookie stuffing**
點浮窗「×」關閉＝靜默走一次 feebee 聯盟連結，你接著購買的佣金從真正推薦者改記營運方。
[`已捕獲` →](findings/02-affiliate-hijacking.md)

**👁️ 3. 跨站瀏覽／搜尋監控**
content script 注入每個網站；把你的搜尋詞（各大引擎）＋購物／watchlist 站的完整網址，用同一個持久 id 縫成跨站剖繪（送出有 gate，非全網每頁）。
[`已捕獲` →](findings/03-browsing-surveillance.md)

**📢 4. 未揭露自家廣告注入**
在搜尋結果頁插入「第三方」廣告，但廣告主機標頭是 `Feebee Web Server`＝同一營運方的自我交易。
[`程式碼具備＋外部` →](findings/04-ad-injection.md)

**🎛️ 5. 伺服器遠端行為控制／規避審查**
每頁向伺服器取設定決定行為，可隨時改／關、免商店更新——靜態單點審查失效。
[`已捕獲` →](findings/05-remote-behavior-control.md)

**🆔 6. 持久指紋 id＋對外連接面**
只產一次、持久保存的隨機 id＝撐過清 cookie 的追蹤 supercookie；manifest 另開放 feebee 網頁直連擴充。
[`已捕獲` →](findings/06-persistent-fingerprint.md)

**📊 7. 搜尋頁廣告版位＋結果情報**
讀你搜尋結果頁：哪些廣告主佔付費版位、落點、自然結果——綁在真人查詢上的市場情報。
[`已捕獲` →](findings/07-search-intelligence.md)

**📋 8. watchlist／完整網址追蹤**
一份伺服器可設定的 watchlist（含 bing／biggo／findprice／gemini／chatgpt），回報你在這些站的**完整網址**——路徑＋query＝搜尋詞、對話 id，正是 HTTPS 要保護的那一段。
[`已捕獲` →](findings/08-watchlist-tracking.md)

## 次要行為
- **安裝／移除歸因**：安裝時 `background.js`（`l()`）讀 `flybeeSourceTrack` cookie、送 GA4「安裝來源（utm）」事件、開歡迎頁；manifest 的移除 URL（`feebee.com.tw/flybee/uninstall`）以 feebee cookie 觸達。
- **其他自家廣告位**：除了 sitemaji 廣告（發現 4），還注入優惠券廣告 banner（`coupon-ad-banner`，連向 feebee 自家媒體）與 MGM 拉人頭單元——同為 feebee 自家版位。
- **每日心跳信標**：`ec.js`（`bck-log`，2433–2449）以 24 小時節流，對 `api.feebee.com.tw/ext/v1/collect` 送一個 Image beacon——週期性回報「這個安裝還活著」的存在訊號（隨圖片請求帶 feebee cookie）。

## 複現
1. 自 Chrome Web Store 抓該 ID 之 CRX；`head -c 4` 應為 `Cr24`；`sha256sum` 比對上方雜湊。
2. `unzip` 解出；`js-beautify` 反混淆 `background.js`/`ec.js` 等。
3. 依各發現之 `檔:符號` 定位、核對行為。
4. 對命中清單之 URL 重打 `ec-config`（一般消費者連線即可），檢視 `promo.mode`、`shopCrawler` 等欄位。

## 檔案
| 路徑 | 內容 |
|---|---|
| [`findings/`](findings/) | 9 項發現的獨立全文（帶行號證據）。 |
| [`REPRODUCE.md`](REPRODUCE.md) | 完整複現步驟。 |
| [`evidence/crx/`](evidence/crx/) | CRX 的 SHA-256 與 `Cr24` 簽章驗證說明（CRX 不隨附，自 Web Store 抓，見 `verify.sh`）。 |
| [`evidence/affiliate-redirects.md`](evidence/affiliate-redirects.md) | 電商目標清單＋各家實測轉址鏈（發現 2）。 |

---
*獨立資安研究，與飛比及其關係企業無隸屬或授權關係。*
