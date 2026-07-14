# 4. 未揭露自家廣告注入（Search-result ad injection）

`程式碼具備＋外部` · [← 回總表](../README.md)

擴充可在搜尋結果頁插入廣告。當「第三方」廣告網其實是同一營運方＝未揭露的自我交易——看似中立結果＋第三方廣告，實則同一方。

## 原理：為什麼「誰家的廣告」很重要
搜尋結果頁被第三方擴充插廣告，本身已是竄改；但真正的問題在**揭露**。若插進來的廣告掛著另一個廣告網（sitemaji）的名義，用戶會以為那是獨立第三方的商業內容。一旦查出那個廣告網其實與擴充後端同屬一家，這就成了**未揭露的自我交易**：同一方既決定你看到什麼「中立結果」，又自己供應「第三方廣告」並收廣告費，兩邊利益不對用戶揭露。

## 程式碼
`google.js`（1149–1161）：搜尋頁若有 `.promo-ad-banner` 容器，就打 sitemaji 的 `ask.php` 取素材、注入、點擊記 `sitemaji_ad`：

```js
o.querySelector(".promo-ad-banner") &&
fetch("https://rd.sitemaji.com/ask.php?size=25x1&hosthash=870f5303c273", { method: "GET" })
  .then(e => e.json()).then(t => {
    const i = t.s150x150.ad_list[0];            // 廣告素材
    const r = document.createElement("a");
    r.href = i.ad_url;                          // 落點
    r.innerHTML = `<img ... src="${i.ad_img}">`; // 塞圖
    r.addEventListener("click", () => te(f, { unit: "sitemaji_ad", ... }));
    n.appendChild(r);
  })
```

bing／yahoo／youtube 同款。

## 外部佐證
`*.sitemaji.com`（`rd`／`ad`／`test`）回應標頭 `server: Feebee Web Server`——佐證廣告主機＝擴充後端同一營運方。這條證據在程式碼之外，`curl -I` 可獨立驗。

## 影響
用戶看到的搜尋結果被竄改，插入由擴充自家營運方供應、卻以另一廣告網名義呈現的廣告。

## 自己抓
`curl -I https://rd.sitemaji.com/ask.php` 讀 `server:` 標頭。版位檔期制，未上檔時 `ask.php` 可能回 `ad_num:0`、無素材可抓。

> 邊界：「sitemaji＝feebee 同一營運方」由 HTTP 標頭佐證（可複現）；「擴充刻意隱瞞關係」屬解讀，留給讀者判斷。
