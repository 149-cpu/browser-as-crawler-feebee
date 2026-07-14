# 6. 持久指紋 id＋對外連接面（Persistent fingerprinting id + externally_connectable）

`已捕獲` · [← 回總表](../README.md)

只產生一次、被持久保存的隨機 id＝跨工作階段的持久追蹤 id（撐過清 cookie 的 supercookie）。另外 manifest 的 `externally_connectable` 讓特定網頁能直接對擴充送訊息。

## 原理：一個 id 讓所有資料流變成「你」
[發現 3](03-browsing-surveillance.md) 的瀏覽／搜尋資料若沒有共同鍵，只是一堆匿名事件。這裡的 id 在首次安裝時產生一次、存進 `storage.local`、之後每次上報都重用——它不放在 cookie 裡，所以你清 cookie、開無痕都不會換掉它（俗稱 supercookie）。有了這個穩定鍵，散在各站、各工作階段的事件就全部歸戶到同一個人。另外 manifest 的 `externally_connectable` 開了一道口：讓 `*.feebee.com.tw` 的網頁能直接對擴充發訊息、查詢它。

## 程式碼
`background.js` 的 `u()`（102–108）：`crypto.getRandomValues` 產一個 UUID、存 `storage.local`、有就重用：

```js
function u() {
    return e.g.env.storage.local.get(t).then(n => {
        let a = "";
        // 已存過就沿用；沒有才用 crypto.getRandomValues 產一個新的 UUID 並存起來
        return n && Object.keys(n).length !== 0
            ? a = n[t]
            : (a = ([1e7]+-1e3+-4e3+-8e3+-1e11).replace(/[018]/g,
                  e => (e ^ crypto.getRandomValues(new Uint8Array(1))[0] & 15 >> e/4).toString(16)),
               e.g.env.storage.local.set({ [t]: a })), a
    })
}
```

這個 `u()` 的回傳被重用為 GA4 `client_id`（`background.js:72`／`:119`，POST `google-analytics.com/mp/collect`）。manifest `externally_connectable.matches=["*://*.feebee.com.tw/*"]`；worker 註冊 `onMessageExternal`，handler（`background.js:53–57`）目前僅回應 `checkInstallStatus`——即 feebee 網頁可探測「你裝了沒」。

## 影響
兩個危害疊加：①穩定 id 把瀏覽／搜尋資料流（[發現 3](03-browsing-surveillance.md)）綁成跨階段單一剖繪；②`externally_connectable` 讓任何 `*.feebee.com.tw` 網頁能**靜默偵測你裝了這支擴充**——網站本來無法列舉你裝了哪些擴充，這本身就是一個指紋／去匿名向量。而因為擴充的遙測都帶 `credentials:"include"`（你的 feebee cookie）又標同一個持久 id，這份剖繪對 feebee 而言**不是匿名的**，是綁在你 feebee 身分下的。

## 自己抓
從 CRX 讀 `manifest.json` 的 `externally_connectable`；grep worker 找持久化又重用為分析 id 的 UUID：

```
python3 -c "import zipfile,json;z=zipfile.ZipFile('feebee-3.55.0.crx');print(json.loads(z.read('manifest.json'))['externally_connectable'])"
```

> 範圍：`onMessageExternal` 這條「網頁→擴充」通道目前只回 `checkInstallStatus`（裝了沒），不從這裡吐 id——但這不是安慰：「網站能確認你是用戶」本身就是危害，加上後端已透過 credentials＋持久 id 掌握你的身分，匿名性早已不存在。回什麼由 worker 程式碼決定、可隨改版擴充。
