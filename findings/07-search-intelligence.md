# 7. 搜尋頁廣告版位＋結果情報（Search-engine ad-slot & result intelligence）

`已捕獲` · [← 回總表](../README.md)

在搜尋引擎上，擴充用 server 給的 selector 讀結果頁，蒐集「某查詢跑出哪些廣告、哪些結果」——綁在真人查詢上的搜尋廣告市場情報。

## 原理：把每個用戶變成競品情報探針
搜尋廣告情報（誰在買哪些關鍵字、廣告落在第幾位、自然結果排名）是有價商品，平常要靠專門爬蟲大規模抓、還會被反爬。這裡改成：安裝擴充的真人每做一次 Google／Bing／Yahoo／YouTube 搜尋，擴充就順手把「這個查詢的付費版位、廣告落點、前幾筆自然結果」回傳後端。因為來自真實用戶的真實搜尋，資料乾淨、難被反爬擋，等於把每個用戶變成一具搜尋情報探針。

## 程式碼
`google.js` 的 `we()`（688–696）收集結果頁上的連結，`Ce`（≈806）把付費／自然版位打包 POST 到 `x_enable-google.php`：

```js
function we(e, o) {                       // e=selector（server 下發）
    const t = document.querySelectorAll(e), i = [];
    for (let x = 0; x < t.length; x++)
        i[i.length] = /yahoo|bing/.test(o) ? t[x].textContent.split("›")[0] : t[x].href;
    return i;                             // 回傳結果頁上的一串 URL
}
// …組成 body：has_pla / has_top_ad[] / has_bottom_ad[] / url[]（前 ~10 筆自然結果）…
const i = `has_pla=${e.pla}${le({position:"top",ads:e.topAd})}${/*&url[]=…*/}${le({position:"bottom",ads:e.bottomAd})}`;
fetch("https://api.feebee.com.tw/ext/v1/x_enable-google.php", { method:"POST", body:i, ... })
```

回應的 `enabled` 再決定是否注入自家單元。

## 影響
每次搜尋，後端得知哪些廣告主佔付費版位、落點、自然結果——真人查詢蒐集的市場情報。

## 自己抓
開著擴充在 Google 搜尋，Network 看有無帶 `has_top_ad[]`／`url[]` 的 POST 打向 `x_enable-google.php`。
