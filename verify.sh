#!/usr/bin/env sh
# 被分析版本的一鍵驗證。需要：curl、sha256sum、unzip。
# 下載簽章 CRX、檢查 Cr24 簽章＋釘死的雜湊、解包、抓取線上伺服器設定。
# 唯讀；任何一般連線皆可執行。
set -eu

ID="lmldjiibpfhdjjdjapcdlpjgeaihflpi"
CRX="feebee-3.55.0.crx"
WANT="a3dbe9210f9a12f2e6ec4b199dfecce1afab5c77176237cc3fabe7f8c4fc42ba"

echo "== 1. 自 Web Store 下載簽章 CRX =="
curl -sL -A "Mozilla/5.0 Chrome/131.0.0.0" \
  "https://clients2.google.com/service/update2/crx?response=redirect&acceptformat=crx2,crx3&prodversion=131&x=id%3D${ID}%26uc" \
  -o "$CRX"

echo "== 2. 簽章＋雜湊 =="
head -c 4 "$CRX" | grep -q "Cr24" && echo "[ok] Cr24 簽章容器"
GOT="$(sha256sum "$CRX" | cut -d' ' -f1)"
echo "實得： $GOT"
echo "應為： $WANT"
[ "$GOT" = "$WANT" ] && echo "[ok] 與被分析版本逐位元相同" \
                     || echo "[!] 雜湊不符——可能已上線更新版本"

echo "== 3. 解包  （另行反混淆：npx js-beautify -r extracted/ec.js extracted/background.js） =="
rm -rf extracted && mkdir extracted && (cd extracted && unzip -oq "../$CRX")
echo "[ok] 已解包到 ./extracted"

echo "== 4. 線上伺服器設定（找 promo.mode / shopCrawler） =="
# 用真實商品／賣家 URL 輸出更豐富；只給裸 host 也足以看出形狀。
curl -s -H "fb-agent: flybee-v3.55.0" \
  "https://api.feebee.com.tw/ext/v1/ec-config?url=https%3A%2F%2Fshopee.tw%2F&version=3.55.0" \
  | head -c 600; echo
