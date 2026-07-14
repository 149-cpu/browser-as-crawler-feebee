# 聯盟轉址鏈 — 發現 2 的佐證證據

**聯盟歸因劫持（cookie stuffing）** 的支持資料。

**轉址怎麼取得。** 在支援的電商頁上，content script 先抓 `ec-config`（拿到 `bck`），再打 `x_result.php`，其回應帶 `page.tracking_url`，形如 `https://feebee.com.tw/rd/<token>`。跟著那個 URL 的 302 鏈走，會落在該電商的商品頁、並被附上 feebee 自己的聯盟歸因參數。任何人都能重現：取得一個 `page.tracking_url`、跟它的轉址（`curl -sL -o /dev/null -w '%{url_effective}'` 或 `--head` 鏈）。

下方所示歸因參數是 **feebee 的**，由伺服器端 `/rd/` 轉址附加（不在擴充程式碼裡——見發現 2）。每次請求的 token 以 `<token>` 呈現。

---

## A. 啟用／目標清單

擴充會啟用的 host（`ec.js` `DOMContentLoaded` host 白名單，≈2452），因而可被下發 `tracking_url`：

```
tw.mall.yahoo.com          www.rakuten.com.tw        www.books.com.tw
search.books.com.tw        www.momomall.com.tw       24h.pchome.com.tw
shopping.pchome.com.tw     ecssl.pchome.com.tw       ecshweb.pchome.com.tw
shopee.tw                  www.sanmin.com.tw         tw.bid.yahoo.com
www.shop2000.com.tw        www.pcone.com.tw          pcone.com.tw
www.momoshop.com.tw        cart.momoshop.com.tw      tw.buy.yahoo.com
twpay.buy.yahoo.com        www.taaze.tw              www.eslite.com
www.u-mall.com.tw          www.etmall.com.tw         shopping.friday.tw
www.kingstone.com.tw       www.iread.com.tw          www.pinkoi.com
www.trplus.com.tw          www.postmall.com.tw       www.myacg.com.tw
*.jollybuy.com             readmoo.com               mall.3785tv.com
online.senao.com.tw        www.citiesocial.com       www.kobo.com
www.zalora.com.tw          www.e-payless.com.tw      www.autobuy.tw
shop.7-11.com.tw           www.treemall.com.tw       www.myfone.com.tw
mamilove.com.tw            www.buy123.com.tw         online.carrefour.com.tw
www.17life.com             www.setddg.com            www.mysport.com.tw
www.strawberrynet.com      www.watsons.com.tw        www.eclife.com.tw
www.s3.com.tw              www.tkec.com.tw           www.tk3c.com.tw
www.tk3c.com               www.isunfar.com.tw        100mountain.com
www.sanjing3c.com.tw       www.everrichtohome.com    www.costco.com.tw
www.beautystage.com.tw     online.skm.com.tw         www.86shop.com.tw
www.ruten.com.tw           eshop.fayaque.com.tw      www.pcstore.com.tw
udesign.udnfunlife.com     www.9x9.tw                shop.cosmed.com.tw
shop.greattree.com.tw      www.pickup.com.tw         www.10mart.com.tw
online.twglobalmall.com    www.demall.com.tw         www.rt-mart.com.tw
www.tw.coupang.com         www.hotaigo.com.tw        mall.iopenmall.tw
shopping.gamania.com       online.uni-prosperity.com.tw
```

## B. 實測轉址鏈

每個 `feebee.com.tw/rd/<token>` 都會解析到帶 feebee 歸因的電商商品頁。以下對線上端點實測；電商與其所用聯盟網因站而異。

**momo（`momoshop`）— 電商自家 CPA**
```
feebee.com.tw/rd/<token>
  → 302  www.momoshop.com.tw/goods/GoodsDetail.jsp?i_code=<id>&utm_source=CPA&utm_medium=feebee_<token>.99&osm=feebee
```
歸因 `osm=feebee`；起點與終點是同一商品（`i_code`）。

**博客來（`books.com.tw`）— 第三方聯盟鏈**
```
feebee.com.tw/rd/<token>
  → 302  adcenter.conn.tw/redirect_wa.php?...&uid2=feebee
  → 302  igamepark.biz/redirect.php?...&uid2=feebee
  → 302  www.books.com.tw/exep/assp.php/vip--<affiliate-code>/products/<id>
```
經 `adcenter.conn.tw` → `igamepark.biz` → 電商的聯盟計畫；`uid2=feebee`。

**PChome（`24h.pchome.com.tw`）— 電商自家**
```
feebee.com.tw/rd/<token>
  → 302  24h.pchome.com.tw/prod/<id>?utm_source=feebee&utm_medium=cpc
```

**Coupang（`tw.coupang.com`）— Coupang Partners（AppsFlyer）**
```
feebee.com.tw/rd/<token>
  → 302  coupang.onelink.me/...?pid=coupang_partners&af_c_id=AF6851883
  → 302  link.tw.coupang.com/gl/tw/TWAFSDP?...
  → 302  www.tw.coupang.com/products/<id>?...&pid=coupang_partners...
```
歸因：Coupang Partners `pid=coupang_partners`、`af_c_id=AF6851883`（AppsFlyer，一個行動歸因平台）。

**蝦皮（`shopee.tw`）— 蝦皮聯盟（AppsFlyer）**
```
feebee.com.tw/rd/<token>
  → 302  s.shopee.tw/<short>
  → 302  shopee.tw/<path>?...&utm_medium=affiliates&utm_source=an_16142330000&mmp_pid=an_16142330000&utm_content=<...>-flybee--reload-
```
歸因：`utm_source=an_16142330000`、`mmp_pid=an_16142330000`。注意 `utm_content` 內含 `flybee--reload-`，對應擴充的 `isReload` 路徑（發現 2／發現 5）。

**誠品（`eslite.com`）— 電商自家**
```
feebee.com.tw/rd/<token>
  → 302  www.eslite.com/product/<id>?utm_source=feebee&utm_medium=cpc&utm_campaign=feebee
```

## C. 共通的歸因識別碼

每一條解析後的連結都帶一個 feebee 識別碼——`osm=feebee`／`utm_source=feebee`／`uid2=feebee`／`pid=coupang_partners`（帳號 `AF6851883`）／`utm_source=an_16142330000`——外加 `bck` token 與一個 `.99` 後綴（feebee 的點擊／用戶追蹤碼）。正是這些值，覆寫掉推薦者原本應持有的 last-click 歸因。
