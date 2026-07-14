# 1. 任意 URL 隱形載入（Hidden background tab）

`程式碼具備·可遠端開` · [← 回總表](../README.md)

背景／service worker 可在隱藏、不聚焦分頁載入 URL、載完即關。若 URL 由伺服器指定且未驗證，就成通用原語：讓瀏覽器對「任何東西」發 HTTP 請求——用用戶 IP＋cookie session、隱形。是 cookie stuffing、廣告曝光／點擊詐欺、CSRF（跨站請求偽造）式強制請求的引擎。

## 原理：為什麼一個「隱形分頁」是萬能工具
瀏覽器分頁會**帶著你的 cookie、IP、登入態**對目標站發出完整請求。看得見的分頁你至少知道它開了；一個 `active:false`＋`pinned` 的背景分頁，載入、觸發、關閉全程無 UI。當「載入哪個 URL」不是寫死、而是伺服器隨時下發時，它就從「開個分頁」升級成**請求偽造引擎**：後端說打哪、瀏覽器就用你的身分打哪，你不會看到也不會同意。聯盟 cookie 置換、廣告曝光／點擊灌水、對第三方站的 CSRF——共用這一個原語。

## 程式碼
`background.js` 的 `case "promo"`（169–183）——收到 `{source:"promo", url}` 就開隱藏分頁、`complete` 即關：

```js
case "promo":
    (function(t) {
        if (!t) return;
        const n = { active: !1, url: t, pinned: !0 };   // active:false = 不聚焦、無感
        e.g.env.tabs.create(n, (async t => {
            const n = t.id;
            e.g.env.tabs.onUpdated.addListener(((t, a) => {
                if ("complete" === a.status && n === t)
                    return void e.g.env.tabs.remove(n)   // 載完立刻關
            }))
        }))
    })(t.url)
```

`t.url` 全程無驗證、無網域白名單。餵入來源是 content script `ec.js` 的 `et()`（≈1005–1008）post `{source:"promo", url}`，`url` 來自 `ec-config` 回應的 `page.tracking_url`（`ec.js:356`）＝**伺服器下發、可隨時改**。這條路徑只在 `promo.mode==="newTab"` 時到達（`ec.js:214–216`）。

## 影響
啟用時，後端一句設定就能令你的瀏覽器靜默載入任意 URL——用你的 IP 與登入 cookie——去置換／刷新聯盟 cookie、灌廣告曝光或點擊、或對任何端點發請求，全程無可見分頁、無提示。

## 自己抓
grep worker 找帶 `active:false` 的 `tabs.create`，看 URL 是否驗證、從哪來；再檢視各 `ec-config` 回應的 `promo.mode`。通則：**未驗證、伺服器給的 URL 在隱藏分頁載入＝請求偽造原語，不論當下用途。**

> 邊界：本次 6 份擷取設定 `promo.mode` 全為 `reload`（當前分頁導向，非開隱藏分頁）；隱藏分頁路徑需 `newTab`，該旗標後端隨時可設——這是**伺服器可切換的休眠能力**，非本次觀測到正在運行的行為。
