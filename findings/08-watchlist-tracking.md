# 8. watchlist／完整網址追蹤（Watchlist / full-URL visit tracking）

`已捕獲` · [← 回總表](../README.md)

在每個網站執行的 content script 挑出一份伺服器可設定的 watchlist，把你在這些站的**完整網址**（含路徑、query、fragment）回傳後端——含 SPA 換頁的每一次。

## 原理：一個「完整 URL」洩漏的，正是 HTTPS 要保護的那一段
很多人以為網址頂多洩漏「你去了哪個站」——錯。`traffic.js` 送的是 `window.location.href`＝**完整 URL**：協定、網域、**路徑、query string、甚至 fragment 全都在內**。而路徑與 query 正是 TLS 加密特意保護的部分：網路上的竊聽者（ISP、公共 WiFi、中間節點）因為 HTTPS 只看得到你連到哪個**網域**（SNI／DNS），看不到後面的路徑與參數。把整串 `location.href` 外傳給 feebee，等於把 TLS 特意保護的那一段，主動交出去。而路徑與 query 裡動不動就裝著高度敏感的東西：

- **搜尋詞本身**——`bing.com/search?q=…`、`findprice…?q=…`：query 就是你查的內容
- **對話／文件／訂單 id**——`chatgpt.com/c/<id>`、`gemini.google.com/app/<id>`、雲端文件 `.../d/<id>`
- **分享連結、重設密碼 token、帶個資的 query 參數**——凡塞進 URL 的，一律隨之外洩

## 程式碼
watchlist 是 `traffic.js`（`http(s)://*/*`）裡的一串 regex（173），命中才掛 hook：

```js
[/feebee.com.tw/, /www.feebee.com.tw/, /www.bing.com/, /www.biggo.com.tw/, /biggo.com.tw/,
 /www.findprice.com.tw/, /gemini.google.com/, /chatgpt.com/].some(e => e.test(location.host))
```

命中後 hook `history.pushState`／`replaceState`＋document `MutationObserver`（175–183），每次換頁觸發 `k()`（143–165）把**完整網址**送出：

```js
function k() {
    const e = `https://api.feebee.com.tw/ext/v1/traffic?uri=${encodeURIComponent(window.location.href)}&version=...`;
    fetch(e, { credentials: "include", ... })   // 完整 location.href；credentials:include = 綁 feebee 身分
      .then(...).then(() => /* 另發 GA4 traffic_tracking，帶 screen_resolution */)
}
```

`MutationObserver`＋`pushState` hook 讓連 SPA（單頁應用，換頁不重載）的每次站內跳轉都抓得到——一般只看整頁載入的追蹤會漏掉這些。名單寫死在 content script（可 grep 印出），但同一套機制天生就是伺服器可擴充的。

## 影響
feebee 收到你在清單內每個站的**完整網址**，綁在你的 feebee 身分下。對 bing／findprice／biggo 這類站，query string 就是你打的**搜尋詞**——你查了什麼一覽無遺；對 ChatGPT／Gemini，網址含對話 id（`chatgpt.com/c/<id>`），可長期追蹤你何時、多常、開了哪些對話。凡把敏感資料塞進 URL 的頁面（重設連結、分享 token、帶個資的參數），一併落入 feebee。

## 自己抓
開著擴充去 `chatgpt.com` 或 `bing.com/search?q=…`，Network 看有無 GET 打向 `.../traffic?uri=…`，`uri` 參數是否為你當下的**完整網址**；站內換頁再看是否又送。

> 範圍：這支函式送的是**網址字串**（`location.href`），不含 POST 內容或頁面 HTML——但這不是安慰：只要站台把內容放進 URL（搜尋詞、對話／文件 id、token），URL 本身就已經是內容。
