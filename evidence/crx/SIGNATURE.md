# 驗證 CRX 發行者簽章

Chrome 的 `.crx`（v3）是簽章容器：一個 `Cr24` 標頭＋一段 protobuf（內含發行者的 RSA 公鑰與對 ZIP 內容的簽章），後面才接 ZIP 本體。

```sh
head -c 4 feebee-3.55.0.crx | xxd     # 4372 3234  => "Cr24"  （簽章容器）
sha256sum  feebee-3.55.0.crx          # 與本目錄的 SHA256SUMS 比對
```

擴充 ID 由此標頭內嵌的發行者公鑰推導而來，故簽章把這些位元組綁到 Web Store 上架項目 `lmldjiibpfhdjjdjapcdlpjgeaihflpi`。這就是為何被釘死的版本無法被推說成偽造：重下載、重算雜湊，即可。
