# AI Gakufu — デプロイ後チェックリスト（AdSense再申請までの道筋）

このチェックリストは、**今日から AdSense 再申請までに実施する作業** を時系列で並べたものです。各項目にかかる時間・クリックする具体URLまで書いています。

---

## ▶️ 今日やる（所要15分）

### ✅ Step 1. GA4プロパティ作成（10分）

1. ブラウザで以下を開く：https://analytics.google.com/
2. `tianbianyoushu786@gmail.com` でログイン
3. 画面左下の「管理」（歯車アイコン）をクリック
4. 「アカウントを作成」または既存アカウント内で「プロパティを作成」
   - アカウント名：`AI Gakufu`
   - データ共有設定：全部チェックOK
5. プロパティ作成
   - プロパティ名：`AI Gakufu`
   - レポートのタイムゾーン：`(GMT+09:00) 日本`
   - 通貨：`日本円 (JPY)`
6. ビジネスの詳細
   - 業種：`Arts & Entertainment`
   - ビジネスの規模：`小`
7. ビジネス目的：`ベースラインのレポートを取得する`
8. 「データストリームを作成」→「ウェブ」
   - ウェブサイトのURL：`https://ai-gakufu.com`
   - ストリーム名：`AI Gakufu Website`
9. 作成後に表示される **測定ID** をコピー（`G-XXXXXXXXXX` 形式）

### ✅ Step 2. 測定IDをコードに反映（1分）

**やり方A（おすすめ）：GitHubから直接編集**
1. https://github.com/tianbianyoushu/skill-zero-ai-creator-launch-lp/edit/claude/crazy-darwin/suno-sheet-music/frontend/analytics.js を開く
2. `const GA_ID = 'G-XXXXXXXXXX';` の `G-XXXXXXXXXX` を実際の測定IDに置換
3. 「Commit changes」→ ブランチ直接コミット
4. Render が自動デプロイ（2〜5分）

**やり方B：ローカルで置換**
```bash
cd /Users/tanayuu/ClaudeBanana/.claude/worktrees/crazy-darwin/suno-sheet-music
# エディタで frontend/analytics.js を開いて GA_ID を書き換え
git add frontend/analytics.js
git commit -m "Set GA4 measurement ID"
git push
```

### ✅ Step 3. GA4で計測開始を確認（2分）

1. ai-gakufu.com をブラウザで開く（自分のアクセス）
2. https://analytics.google.com/ → プロパティ → 左メニュー「リアルタイム」
3. 1〜2分以内にアクティブユーザー「1」が表示されればOK

---

## ▶️ 明日〜3日以内にやる（所要20分）

### ✅ Step 4. Search Console にサイトを再登録（5分）

1. https://search.google.com/search-console を開く
2. プロパティセレクタから「プロパティを追加」→「URLプレフィックス」
3. URL: `https://ai-gakufu.com/` を入力
4. 所有権確認 → **既に HTML タグ（`google-site-verification`）が `index.html` に入っているので自動的に検証されます**
   - もし検証できなかったら、表示されるメタタグを `index.html` の `<head>` 最上部に手動で貼り付け

### ✅ Step 5. sitemap.xml を送信（3分）

1. Search Console 左メニュー「サイトマップ」をクリック
2. 「新しいサイトマップの追加」に `sitemap.xml` と入力
3. 「送信」
4. ステータスが「成功しました」になればOK（数分〜数時間）

### ✅ Step 6. 主要URLのインデックス登録をリクエスト（10分）

Search Console 上部の検索窓に以下のURLを1つずつ貼り付け → Enter → 「インデックス登録をリクエスト」ボタン。

**リクエスト推奨URL（優先順）：**
```
https://ai-gakufu.com/
https://ai-gakufu.com/blog/
https://ai-gakufu.com/howto.html
https://ai-gakufu.com/faq.html
https://ai-gakufu.com/about.html
https://ai-gakufu.com/blog/suno-ai-score-guide.html
https://ai-gakufu.com/blog/how-ai-transcribes-music.html
https://ai-gakufu.com/blog/read-sheet-music-basics.html
https://ai-gakufu.com/blog/piano-vs-guitar-score.html
https://ai-gakufu.com/blog/why-transcribe-your-music.html
https://ai-gakufu.com/blog/suno-ai-prompt-tips.html
```

※ 1日に登録リクエストできるURLは10件程度までの制限があります。最初の日で10個投げ、翌日残りを投げてください。

### ✅ Step 7. 検索でインデックス状況を確認（2分）

Google検索窓で `site:ai-gakufu.com` と打って検索。ページが表示されていればOK（初回は2〜3日かかる）。

---

## ▶️ 1週目（所要2時間、毎日15〜20分）

### ✅ Step 8. SNS運用開始

`SNS-CONTENT.md` の「第1週：ローンチウィーク」に従って投稿開始。具体的には：

- 月：X にポスト1 + note 記事投稿
- 火：Reddit r/SunoAI 投稿
- 水：X ポスト2
- 木：Instagram Reel
- 金：X ポスト8
- 土：Discord 自己紹介
- 日：X ポスト5

**毎回のチェック：**
- 投稿後30分以内に返信が来たら必ず返す
- GA4 でその投稿経由の流入を確認
- 一番反応のあった投稿のパターンを記録

### ✅ Step 9. 初週のKPI（最低ライン）

- GA4アクティブユーザー：過去7日で **30人以上**
- Search Consoleクエリ：最低1件でも表示されればOK
- Xフォロワー：+10人以上

---

## ▶️ 2〜3週目（毎日10分の維持）

`SNS-CONTENT.md`「第2週」「第3週」のスケジュール通り投稿継続。

**この期間にやらないこと：**
- AdSense再申請（まだ早い）
- サイトの大幅変更（審査のぶれを防ぐ）

**やること：**
- 毎日GA4を1分確認
- 週1回Search Console確認
- SNS投稿は欠かさず

---

## ▶️ 4週目：AdSense再申請！

### ✅ Step 10. 再申請前の最終チェック（30分）

以下すべてYESで再申請可。

- [ ] GA4で過去30日のアクティブユーザー **50人以上**
- [ ] Search Consoleで表示回数 **100回以上** or クエリ **10個以上**
- [ ] Googleに `site:ai-gakufu.com` で検索して **8〜10ページがインデックスされている**
- [ ] ブログ記事6本がすべて検索窓から読める
- [ ] プライバシーポリシー・利用規約・運営者情報のリンクが全ページフッターから辿れる
- [ ] モバイルでも全ページが正常に表示される（https://search.google.com/test/mobile-friendly でテスト）
- [ ] Core Web Vitals で致命的な問題がない（https://pagespeed.web.dev/ で index.html を検査）

### ✅ Step 11. AdSense再申請（5分）

1. https://www.google.com/adsense/ にログイン
2. サイト一覧から `ai-gakufu.com` を選択
3. 「審査をリクエスト」をクリック
4. 結果通知は通常 **2日〜2週間** で届く

### ✅ Step 12. 申請中の注意

- サイトを変更しない（特にナビ・プライバシーポリシー・構造）
- 急激なトラフィック変動を避ける（自然な増加はOK、自作自演はNG）
- AdSenseアカウントで別のサイトを審査中にしない

---

## 📊 進捗トラッキング用チェックボックス

コピペして `docs/progress-2026-04.md` などに貼り付けて使うと便利。

```markdown
## AdSense再申請までの進捗（2026年4月〜5月）

### 今日
- [ ] GA4プロパティ作成
- [ ] 測定IDをanalytics.jsに反映
- [ ] リアルタイムで計測確認

### 明日〜3日
- [ ] Search Consoleプロパティ追加
- [ ] sitemap.xml送信
- [ ] 主要10URLのインデックス登録リクエスト

### 第1週
- [ ] X ローンチ告知
- [ ] note記事投稿
- [ ] Reddit r/SunoAI 投稿
- [ ] Instagram Reel 1本
- [ ] Discord自己紹介
- [ ] GA4週次確認（目標：30人）

### 第2週
- [ ] X ポスト5本
- [ ] Reddit r/WeAreTheMusicMakers 投稿
- [ ] Instagram カルーセル 1本
- [ ] 英語ポスト開始

### 第3週
- [ ] X ポスト5本
- [ ] Reddit r/musictheory 投稿
- [ ] Instagram カルーセル 1本
- [ ] 英語ポスト継続

### 第4週
- [ ] 再申請前チェックリスト全項目Pass
- [ ] AdSense再申請！
- [ ] （待機期間中）SNS投稿は継続
```

---

## 🆘 トラブルシューティング

### GA4が計測されない
- ブラウザの広告ブロッカーを無効化してから確認
- シークレットウィンドウで開く
- `analytics.js` のGA_IDが正しく置換されているか確認
- Render のデプロイが完了しているか確認（dashboard.render.com）

### Search Console の所有権確認に失敗する
- `curl https://ai-gakufu.com/ | grep google-site-verification` で現状のコードを確認
- 出力: `<meta name="google-site-verification" content="SGig76IxL_yqHbiEtyX6AAozY-0xTl86Ba1oOCZ00HE" />`
- これがなければ index.html に追加してpush

### AdSenseがまた落ちた
- rejection 通知メールを見て理由を確認
- 頻出理由：「コンテンツが不十分」→ 記事をさらに3〜5本追加、各2,000文字以上
- 頻出理由：「価値の低いコンテンツ」→ 既存記事をリライトして独自視点を強化
- 再申請前に **最低1ヶ月のクールダウン**を置くこと

---

## 🎯 最終ゴール

**AdSense承認 → 月額広告収益 1,000〜5,000円** が第一目標。
これを達成したら、

- 記事を月2本追加（年間24本）→ 広告収益10倍の可能性
- 有料プラン導入の検討（精度UP・透かしなしPDF・API提供など）
- 英語サイト版の追加（`en.ai-gakufu.com`）

が次の打ち手です。

健闘を祈ります！🎼
