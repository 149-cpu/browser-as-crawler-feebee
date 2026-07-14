# 從零複現這些發現

這裡的一切都從**公開可下載的擴充**出發。不需帳號、不需內部管道。任何人照著走，都會獨立抵達同一份程式碼與同樣的端點行為。

**一鍵：** 執行 [`verify.sh`](verify.sh)——它會下載 CRX、檢查 `Cr24` 簽章與釘死的雜湊、解包、並抓取線上 `ec-config`。以下是手動步驟。

## 1. 抓到那個確切的版本

從 Chrome Web Store 下載擴充 ID `lmldjiibpfhdjjdjapcdlpjgeaihflpi` 的 CRX（任何 CRX 下載法皆可，重點是**位元組**，不是來源）。

## 2. 確認你拿到同一份檔案

```sh
# 簽章容器 magic：檔案開頭必為 Cr24 簽章標頭。
head -c 4 feebee-3.55.0.crx | xxd          # 應為：4372 3234  （"Cr24"）

# 以雜湊釘死。比對 evidence/crx/SHA256SUMS。
sha256sum feebee-3.55.0.crx
```

CRX 帶發行者簽章（`Cr24` v3 標頭）。因為此版**同時**被雜湊釘死**且**有簽章，廠商日後無法主張被分析的版本是偽造的：位元組可對 Web Store 自己的簽章驗證。

> 把你重抓 CRX 的雜湊填入 `evidence/crx/SHA256SUMS`。若與此處提交的雜湊相符，你看的就是這份筆記所描述的同一版本。

## 3. 解包與反混淆

```sh
# CRX 就是前面接了簽章標頭的 ZIP；unzip 會略過標頭。
mkdir extracted && (cd extracted && unzip -o ../feebee-3.55.0.crx)

# 反混淆打包的 JS，讓行號穩定、人可讀。
npx js-beautify -r extracted/background.js extracted/ec.js   # 及其他打包腳本
```

行號依反混淆工具而定，故各發現以**檔案＋符號／行為**引用，而非原始行號。反混淆後，搜尋被引用的符號即可定位同一段程式碼。

## 4. 定位每項行為

見 [README.md](README.md) 的「發現」段（或 [`findings/`](findings/) 內各項全文）。每項都列出檔案與要搜尋的符號或字串（例如 `ec-config` 消費端的 `promo.mode` 處理）。讀周邊程式碼、自行確認行為。

## 5. 重放公開端點

後端端點是公開的。重放它們即可看到線上設定（含伺服器下推的 `promo.mode` 與 `shopCrawler`）。[`verify.sh`](verify.sh) 已幫你做這件事；請求形狀為：

```sh
# 示意——用真實商品／賣家 URL 會有更豐富的輸出。
curl -s -H 'fb-agent: flybee-v3.55.0' \
  'https://api.feebee.com.tw/ext/v1/ec-config?url=https%3A%2F%2Fshopee.tw%2F&version=3.55.0'
```

> **網路備註。** 若你重放端點，用一般消費者連線即可。這裡沒有任何一項需要特定來源；這些回應是提供給任何呼叫者的設定／廣告。
