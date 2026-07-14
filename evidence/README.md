# evidence/

這裡的一切都源自**公開產物**——簽章過的 CRX（自 Web Store 抓）與公開端點的回應——故任何讀者都能重新產生。逐項發現的分析放在上層 README 與 [`../findings/`](../findings/)；本目錄放的是完整性材料。

## 擺放

```
evidence/
├── crx/           被分析版本的完整性材料。
│   │              CRX 本體「不」隨附——用 ../verify.sh（或任何 CRX 下載器）自 Web Store 抓，再比對。
│   ├── SHA256SUMS             （CRX 的雜湊；重抓後比對）
│   └── SIGNATURE.md           （如何確認 Cr24 發行者簽章）
└── affiliate-redirects.md     發現 2 的佐證：目標電商清單＋各家實測 /rd/ 轉址鏈與歸因參數
```

## 完整性模型

- **CRX** 由 SHA-256 釘死（`crx/SHA256SUMS`），且為簽章過的 `Cr24` 容器。二進位不在此重新散布；`../verify.sh` 會自 Web Store 下載，`head -c 4`＋`sha256sum` 即可確認你拿到的正是這些發現所描述、逐位元相同的版本。發行者簽章把這些位元組綁到 Web Store 上架項目。
- **端點回應**（`affiliate-redirects.md`）可對線上公開端點重現（見 [`../REPRODUCE.md`](../REPRODUCE.md)）；每次請求的 token 以佔位符呈現，不含任何擷取當下或個人資料。
