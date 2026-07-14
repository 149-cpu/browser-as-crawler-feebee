# 0. 借 session 分散式採集（Distributed scraping via borrowed session）

`已捕獲` · [← 回總表](../README.md)

擴充把安裝用戶群變成分散式爬蟲：不從自家伺服器爬（會被限流／封 IP），而是讀「用戶自己已開啟的頁面」內容、在其登入態下回傳。每次讀取都像正常登入真人，難偵測難封鎖（scraping botnet）。

## 原理：為什麼要「借用戶的 session」
一般爬蟲從自家伺服器發請求，平台看流量特徵（同一段 IP、無登入、高頻）就能限流、封鎖、甚至餵假資料。改讓「已裝擴充的真人」在自己登入的分頁裡就地讀 DOM、回傳，每一次抓取都來自不同住宅 IP、真實 cookie、真人操作節奏——平台幾乎無法從正常訪客裡把它挑出來。採哪些欄位、對哪些站開，全由伺服器下發的 selector 決定：改設定即改行為，不必更新擴充、不必再過商店審查。

## 程式碼
`ec.js` 的 `Et()`（2405–2432）：在蝦皮賣場頁（`ecid==="spstore"`）且 `shopCrawler.isActive` 時，用 server 給的 `shopCrawler.dom` selector 逐欄讀賣家指標，拼進上傳 URL：

```js
function Et(e, t, o) {
    let i = "";
    if ("spstore" === t.ecid && t?.shopCrawler?.isActive) {
        // …用 t.shopCrawler.dom 的 selector 逐欄抓（seller_id 另解析 URL pathname）…
        i = `&shop_product_num=${...}&shop_chat=${...}&seller_name=${...}`
          + `&shop_fans=${...}&shop_rank_count=${...}&shop_join_time=${...}`
          + `&sell_chat_response=${...}&seller_id=${...}`
    }
    return `https://api.feebee.com.tw/ext/v1/${e}.php?url=${...}&...${i}`
}
```

擷取當下 `shopCrawler.isActive=true`、selector 是蝦皮的 hash class（`.YnZi6x`…）。同一份 `ec-config` 還帶另外三隻採集器，都吃 server 下發的 selector：

- `srpCrawler`＝你在蝦皮打的搜尋詞（`ec.js:2176–2189`）
- `reviewCrawler`＝評論暱稱／星等／文字／圖（`ec.js:1105–1164`）
- `crawler`＝商品 title／price／image（`ec.js:1089、2246`）

## 影響
賣家指標、你的平台搜尋詞、評論內容，都在你登入態下被讀取回傳；因來自真人，平台難歸因難封鎖，範圍伺服器控。

## 自己抓
對賣場頁重打 `ec-config`，看有無帶 `isActive`＋`dom` selector 的 `shopCrawler`。通則：擴充若注入很廣（`http(s)://*/*`）又從伺服器收 selector 讀頁面＝伺服器指揮的採集，追它送去哪。

> 邊界：讀的是頁面「已渲染 DOM」，非蝦皮 API——擴充所有請求皆指向 feebee／sitemaji，無一指向蝦皮（可 grep 驗證）。
