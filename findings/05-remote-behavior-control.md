# 5. 伺服器遠端行為控制／規避審查（Server-gated remote behavior control）

`已捕獲` · [← 回總表](../README.md)

擴充每頁向伺服器取設定、設定決定行為 → 出貨程式碼只是一半，行為可改可關、免商店更新。良性版本可通過審查、之後才開採集；也可隨時關掉一切（有人在盯時）。靜態單點審查失效。

## 原理：為什麼「看程式碼」不夠
商店審查與資安拆解通常看的是**出貨的靜態程式碼**。但當擴充每次載入頁面都向自家伺服器抓一份設定、再由設定決定「這次要不要爬、爬哪些欄位、要不要開隱形分頁、要不要塞廣告」，程式碼就只是一具引擎，真正的行為在伺服器端、可隨時切換。含義有二：①送審時可回良性設定、過審後再對真實用戶開採集；②有人在拆、在盯時，一個旗標就能把全部關掉、事後矢口否認。因此這類擴充該以「**程式碼具備的能力**」評估，而非「當下這一秒的設定」。

## 程式碼
`ec.js`（2452–2463）：host 命中內建購物站清單才抓 `ec-config`（帶 `credentials:"include"`）；回應含 `crawler` 鍵且 `forceDisabled` 未設，才套用：

```js
[/tw.mall.yahoo.com/, /shopee.tw/, /www.momoshop.com.tw/, …].some(e => e.test(location.host)) &&
fetch(`https://api.feebee.com.tw/ext/v1/ec-config?url=${Be()}&version=${Fe()}`, {
    credentials: "include",
    headers: { "fb-agent": `flybee-v${Fe()}` }
}).then(...).then(t => {
    "not match" !== t.ecid &&
    (Object.keys(t).includes("crawler")
        ? t.forceDisabled || (window.flybeeBck = t.bck, e(t))   // 伺服器沒喊停才套用
        : console.log(`${t.ecid} crawler is not ready`))
})
```

套用的 `t` 決定 `promo.mode`（reload／隱藏 newTab）、`shopCrawler.isActive`、廣告／優惠顯示——全在伺服器回應裡。`forceDisabled`／`crawler is not ready` 這種「遠端隨時可關」的閘門，正是規避審查的形狀。

## 影響
本 repo 每項行為都只差伺服器一個旗標就會變。「現在沒開」≠「不會發生」；開關在營運方伺服器。

## 自己抓
`curl` 對命中 URL 打 `ec-config` 列舉鍵。通則：行為由伺服器布林值把關的擴充，該以「能力」而非「當下設定」評估。
