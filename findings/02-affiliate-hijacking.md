# 2. 聯盟歸因劫持 / cookie stuffing（Affiliate attribution hijacking）

`已捕獲` · [← 回總表](../README.md)

聯盟 cookie stuffing 強迫經聯盟轉址的點擊／載入，覆寫 last-click 歸因 cookie，佣金記給營運方而非真正推薦者。此處觸發是誘導性 UI：比價浮窗的關閉「×」鍵。（是圍繞歸因的 UI 誘導，非透明 iframe 的教科書 clickjacking。）

## 原理：一次「關閉」如何變成一次佣金
聯盟行銷靠 last-click 歸因：你買東西前最後點過的那個聯盟連結，佣金就記給那個推薦者。cookie stuffing 就是在你毫無購買意圖時，偷偷替你走一趟某人的聯盟連結、種下歸因 cookie——等你日後真的下單，佣金被那一方攔走，原本該拿的推薦者（寫開箱的 KOL、通路夥伴）被洗掉。這裡的觸發點特別隱蔽：不是誘你點廣告，而是把「關閉比價視窗」**這個你一定會做的動作**，接到伺服器下發的 `feebee.com.tw/rd/<token>` 轉址上。

## 程式碼
浮窗控制項的處理（`ec.js:1379`）：`isReload` 就把當前分頁導去 `i`、`isNewTab` 就丟給隱形分頁 `et()`（見[發現 1](01-hidden-background-tab.md)）——`i` 即伺服器下發的 `page.tracking_url`：

```js
window.setTimeout((() => {
    s.isReload && (window.location.href = i),   // 導去 server 下發的 tracking_url
    s.isNewTab && et(i)                          // 或丟隱形分頁載入
}), 100)
```

該事件同時 POST 一筆 `x_click.php`（`ec.js:1390`）記錄點擊。`tracking_url` 是 `feebee.com.tw/rd/<token>`，內部記為 `add_affiliate_code`（`ec.js:140`）；聯盟參數由 `/rd/` **伺服器端**加上，擴充程式碼看不到（故此項證據落在轉址鏈，非 JS）。

## 影響
關掉浮窗＝靜默走一次 feebee 聯盟連結；你接著購買的 last-click 歸因從真正推薦者（publisher／創作者／通路夥伴）改記營運方。

## 自己抓
開 Network 點「×」；「關閉」卻導向 `feebee.com.tw/rd/...` 就是跡證。跟轉址鏈看聯盟參數。通則：關閉／取消鍵卻觸發導向＝歸因濫用紅旗。

> 參考：目標電商清單＋各家實測轉址鏈（含 feebee 歸因參數 `osm=feebee`／`uid2=feebee`／`utm_source=an_16142330000`…）見 [`../evidence/affiliate-redirects.md`](../evidence/affiliate-redirects.md)。
