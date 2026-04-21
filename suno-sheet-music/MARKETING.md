# AI Gakufu — マーケティング & AdSense 対応ガイド

このドキュメントは、AI Gakufu（ai-gakufu.com）の **AdSense 審査通過** と **継続的なアクセス獲得** のために実施すべき作業を、優先度順にまとめたものです。

---

## 1. AdSense 審査で落ちた推定原因と対策

### 2026年のAdSense主要基準

Googleは2024年後半以降、「**Low Value Content（低価値コンテンツ）**」を強く除外するようになりました。2026年時点で特に重視されているのは次の3点です。

| 基準 | 説明 | AI Gakufuでの対応 |
|---|---|---|
| **Information Gain** | 他のサイトで得られない独自の価値・知見があるか | 運営者の実体験ベースのブログ6記事を追加（合計約12,000文字）|
| **E-E-A-T** | Experience, Expertise, Authoritativeness, Trust | 著者情報「運営チーム」、運営者ページ、実体験記述で担保 |
| **substantial unique content** | 単なるツール画面だけでなく十分な本文があるか | ブログ + About + Howto + FAQ で可読テキストを確保 |

### 今回の推定落選原因

1. ❌ **ツールだけのサイトで本文が薄い** — index.html は150文字程度、他ページも定型文主体
2. ❌ **コンテンツの独自性が弱い** — 「Suno AI 楽譜化」について運営者視点の知見が書かれていなかった
3. ❌ **構造化データ・OGP が不十分** — Googleがサイトの性質を理解しづらい
4. ❌ **内部リンクが乏しい** — ページ間の回遊導線が弱い
5. ❓ **アクセス数が極端に少ない** — 直接の不合格理由ではないが、「まだ誰にも読まれていない新規サイト」と見なされ品質判断が厳しくなる可能性

### 今回の対策（実施済み）

- ✅ `blog/` 配下に6本の独自ブログ記事を追加（各1,500〜2,500文字）
- ✅ すべての記事に `Article` + `BreadcrumbList` の JSON-LD を付与
- ✅ 全ページに OGP / Twitter Card メタタグを追加
- ✅ `index.html` に `WebSite` / `Organization` / `SoftwareApplication` の JSON-LD を追加
- ✅ `howto.html` に `HowTo` JSON-LD、`faq.html` に `FAQPage` JSON-LD を追加
- ✅ 全ページのナビに「ブログ」リンクを追加し、記事内からツールへのCTAを設置
- ✅ `sitemap.xml` を新URL（ブログ7本）で更新
- ✅ 全ページに Google Analytics 4 のタグを（プレースホルダで）挿入

### 再申請前にやること

1. **GA4 プロパティを作成し、測定IDを差し替え**（後述）
2. Google Search Console に `sitemap.xml` を再送信
3. 各ブログ記事がインデックスされていることを `site:ai-gakufu.com` で確認
4. **申請は2〜4週間待ってから再提出**（コンテンツがクロールされる時間を与える）

---

## 2. Google Analytics 4 (GA4) 設定手順

現在、全ページに以下のタグが**プレースホルダ `G-XXXXXXXXXX` のまま**挿入されています。実測定を開始するには自分の測定IDに置き換えが必要です。

### 手順

1. https://analytics.google.com/ にアクセスしてログイン（`tianbianyoushu786@gmail.com`）
2. 「管理」→「プロパティを作成」
3. プロパティ名：`AI Gakufu`、業種：`Arts & Entertainment`、規模：`小`
4. データストリームで「ウェブ」を選択 → URL: `https://ai-gakufu.com/`
5. 発行される **測定ID（例: G-ABC1234XYZ）** をコピー
6. リポジトリ全体で `G-XXXXXXXXXX` を置換：

   ```bash
   cd /path/to/repo/frontend
   grep -rl 'G-XXXXXXXXXX' . | xargs sed -i '' 's/G-XXXXXXXXXX/G-ABC1234XYZ/g'
   ```

7. コミット & デプロイ
8. GA4 管理画面の「リアルタイム」で自分のアクセスが記録されているか確認

### GA4で最初に見る数値

- **ページあたり平均エンゲージメント時間**：30秒以上が目安
- **オーガニック検索からの流入**：Search Console と連携して確認
- **離脱率の高いページ**：改善候補

---

## 3. Google Search Console 設定

1. https://search.google.com/search-console にアクセス
2. 「プロパティを追加」→ ドメイン（`ai-gakufu.com`）またはURLプレフィックスを選択
3. DNS TXT または HTMLタグで所有権確認（現在 `index.html` に `google-site-verification` 済）
4. 左メニュー「サイトマップ」→ `sitemap.xml` を送信
5. 「URL検査」で主要ページ（`/`, `/blog/`, 各記事）をリクエスト → 「インデックス登録をリクエスト」

### 重点監視指標

- **カバレッジ**：すべてのページが「有効」になっているか
- **検索パフォーマンス**：ターゲットキーワード（下記）での表示回数・順位
- **Core Web Vitals**：LCP / CLS / INP

---

## 4. SEO キーワード戦略

### メインキーワード（SEOで狙う）

| キーワード | 月間検索数目安 | 狙うページ |
|---|---|---|
| Suno AI 楽譜 | 500〜1,500 | `blog/suno-ai-score-guide.html` |
| AI 楽譜生成 | 200〜800 | `index.html` |
| MP3 楽譜 変換 | 300〜1,000 | `blog/how-ai-transcribes-music.html` |
| 楽譜 読み方 | 2,000〜5,000 | `blog/read-sheet-music-basics.html` |
| Suno AI プロンプト | 300〜1,000 | `blog/suno-ai-prompt-tips.html` |
| 自作曲 楽譜 | 200〜600 | `blog/why-transcribe-your-music.html` |

### ロングテールキーワード（記事タイトル・見出しに埋め込み済）

- 「Suno AI で作った曲 楽譜にする」
- 「ピアノ譜 ギター譜 違い」
- 「AI 音声 楽譜 仕組み」
- 「楽譜 音符 種類 初心者」

### やってはいけないSEO

- ❌ キーワード詰め込み（Penaltyの対象）
- ❌ 他サイトからのコピペ
- ❌ AIで量産した無個性記事（Information Gainがない）

---

## 5. SNSマーケティング（アクセス集めの主戦場）

AdSense審査に直接効くわけではありませんが、**実ユーザーの流入がある = 品質の高いサイト**という評価につながります。また広告収益のためにも必須。

### 5-1. X (Twitter)

ターゲット：`#SunoAI` `#AI作曲` `#DTM` `#作曲` のハッシュタグを使う層

**運用パターン**
- 週2〜3回の投稿
- ブログ記事1本公開ごとに、記事の要点をスレッドで解説 + 最後に記事リンク
- Suno AIの新機能リリース時に「AI Gakufuで楽譜化してみた」系の即時投稿
- 楽譜画像（PDFからスクショ）を添付すると保存率が高い

**投稿テンプレ例**
```
🎵 Suno AIで作った曲、楽譜にしたことありますか？

1/ そもそもなぜ楽譜化すると良いのか
2/ どんなツールがあるのか
3/ 実際どこまで精度が出るのか

まとめました👇
https://ai-gakufu.com/blog/suno-ai-score-guide.html
```

### 5-2. Reddit

海外ユーザーにリーチしたい場合の最重要プラットフォーム。

- `r/SunoAI`（日本語でなく英語で）
- `r/WeAreTheMusicMakers`
- `r/musictheory`
- `r/piano`

**注意**：Redditは自サイトへの露骨な宣伝を嫌います。`Show HN` 的なトーン、または「質問→回答の中で自サイトを紹介」が効きます。

### 5-3. Discord

Suno AI 公式 Discord サーバーに「役立つツールだよ」という温度感で投稿。コミュニティ内の Q&A で自然に紹介するのが最強。

### 5-4. Instagram / TikTok

- 楽譜生成の過程を15秒動画にする（アップロード → ぐるぐる → 楽譜完成）
- BGMはその日に生成した曲そのもの
- ハッシュタグ：`#楽譜` `#ピアノ` `#作曲` `#SunoAI` `#AI音楽`

### 5-5. note

既に運営中の `yohaku.days` アカウントとは別ブランドなので、AI Gakufu専用のnote記事を月1本、ブログ記事の抜粋として公開。noteは**Googleが非常に好むドメイン**なのでSEO的にも強い。

---

## 6. コンテンツ拡張計画

AdSense再申請までに時間がある場合、さらに記事を追加するのが最も効く施策です。

### 次に書くべき記事（優先度順）

1. 「Suno AI v4 の新機能まとめ」（ニュース性 × SEO強い）
2. 「楽譜をスマホでスキャンするアプリ比較」（周辺キーワード）
3. 「MIDIとは？音楽制作の基礎知識」（初心者層）
4. 「著作権と自作曲 — Suno AIで作った曲は商用利用できるか」（法務系SEO）
5. 「AI Gakufu 開発日記：こうやって作った」（運営者の"顔"を出す）

各記事は **1,500文字以上、見出し5つ以上、運営者視点の知見を含む** ことが必須。

---

## 7. 継続タスクのチェックリスト

### 毎週
- [ ] Search Console のパフォーマンスを確認
- [ ] GA4 のアクティブユーザー数を確認
- [ ] Xに最低1回投稿
- [ ] Redditコミュニティを巡回（ただし宣伝しすぎない）

### 毎月
- [ ] ブログ記事を最低1本追加
- [ ] 既存記事のリライト（古い情報の更新）
- [ ] sitemap.xml の `<lastmod>` 更新

### 3ヶ月ごと
- [ ] AdSense 管理画面で収益レポートを確認
- [ ] コンテンツが多い場合、カテゴリページを追加して構造化
- [ ] 外部リンク（被リンク）獲得の施策を検討

---

## 8. 再申請の判定基準

以下が揃ったら AdSense 再申請するのが目安です。

- ✅ 記事6本以上（各1,500文字以上、独自視点あり）← **現在達成**
- ✅ 全ページに OGP・JSON-LD 構造化データ ← **現在達成**
- ✅ ナビ・フッターで内部リンク網羅 ← **現在達成**
- ⏳ GA4 で自サイトに**過去30日で最低50セッション以上**の流入がある
- ⏳ Search Console で検索クエリが数十件表示されている

GA4とSearch Consoleの流入データが揃ってから再申請することで通過率が大きく上がります。

---

## 付録：ファイル更新リスト（今回のAdSense対策コミット）

- `frontend/index.html` — OGP, JSON-LD (WebSite/Organization/SoftwareApplication), GA4, blogナビ
- `frontend/howto.html` — OGP, JSON-LD (HowTo), GA4, blogナビ
- `frontend/faq.html` — OGP, JSON-LD (FAQPage), GA4, blogナビ
- `frontend/about.html` — OGP, GA4, blogナビ
- `frontend/privacy.html` — blogナビ
- `frontend/terms.html` — blogナビ
- `frontend/blog/index.html` — 新規作成（ブログハブ）
- `frontend/blog/suno-ai-score-guide.html` — 記事1
- `frontend/blog/how-ai-transcribes-music.html` — 記事2
- `frontend/blog/read-sheet-music-basics.html` — 記事3
- `frontend/blog/piano-vs-guitar-score.html` — 記事4
- `frontend/blog/why-transcribe-your-music.html` — 記事5
- `frontend/blog/suno-ai-prompt-tips.html` — 記事6
- `frontend/sitemap.xml` — ブログURL7件追加
- `frontend/style.css` — ブログ用CSS追加
- `MARKETING.md` — 本ドキュメント
