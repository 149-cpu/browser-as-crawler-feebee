# 3. 跨站瀏覽／搜尋監控（Cross-site browsing & search surveillance）

`已捕獲` · [← 回總表](../README.md)

在每個網站注入的 content script，把你的搜尋詞（各大搜尋引擎）與完整造訪網址（購物站＋一份 watchlist）回傳後端，全部綁在同一個持久 id 下，縫成跨站行為剖繪。

## 原理：一個持久 id，把多個管道的你縫成一個人
content script 以 `http(s)://*/*` 注入**每一個網站**——這是它的攻擊面（且哪些站會啟動採集由伺服器設定，見[發現 5](05-remote-behavior-control.md)）。**注意：注入 ≠ 每頁都回傳**；實際送出目前發生在三類管道：

1. 你在 Google／Bing／Yahoo／YouTube 的**搜尋詞**（`x_result_g.php?title=`）
2. **購物站**（購物白名單，見發現 5）與**一份 watchlist**（含 AI 助理，見[發現 8](08-watchlist-tracking.md)）上的**完整造訪網址**
3. 含來源頁＋關鍵字的**點擊記錄**（`x_click.php`）

三者都帶同一個 `bck` id——於是散在不同站、不同管道的你，被縫成一份可跨站關聯的個人剖繪。搜尋詞與完整網址本身就高度洩露意圖（你在查什麼病、找什麼工作、比什麼價）。

## 程式碼
搜尋詞：`google.js` 的 `Te()`（1253–1257）直接把你的 `searchKeyword` 送 `x_result_g.php?title=`（bing／yahoo／youtube 同款）：

```js
function Te(e) {
    const o = `https://api.feebee.com.tw/ext/v1/x_result_g.php`
            + `?title=${encodeURIComponent(e.searchKeyword)}`   // 你打的搜尋詞
            + `&...&bck=${encodeURIComponent(window.flybeeBck)}` // 綁 bck id
    fetch(o, { headers: { bck: encodeURIComponent(window.flybeeBck) } })...
}
```

完整網址走兩條 **gated** 管道：`ec-config?url=<href>`（購物白名單觸發，`ec.js:2462`）、`traffic?uri=<href>`（watchlist 觸發，`traffic.js:144`，`credentials:"include"`）；點擊記錄 `x_click.php`（`ec.js:1390`、`google.js:1233`）。皆帶 `bck`。注入面 `ec.min.js`／`traffic.min.js` 配 `http(s)://*/*`，但**送出按上述 gate**。

## 影響
你的搜尋意圖（各大引擎）＋購物站與 watchlist 站的完整網址，全部歸戶到同一個持久 id（見[發現 6](06-persistent-fingerprint.md)），跨站、跨工作階段關聯成單一剖繪。

## 自己抓
在 Google 搜尋、在購物站、在 watchlist 站（如 `chatgpt.com`）開 Network，看有無帶你搜尋詞／完整網址的請求打向 `api.feebee.com.tw/ext/*`；在**不相干的一般網站**則應看不到送出（注入在、送出有 gate）。查 `manifest.json` 的 `matches` 確認注入面。
