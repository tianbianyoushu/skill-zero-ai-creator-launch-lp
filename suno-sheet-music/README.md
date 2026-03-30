# Suno Sheet Music Generator

SunoAIで作った楽曲を **ピアノ譜（大譜表）** と **ギター譜（五線 + タブ譜）** に変換してPDFダウンロードできるWebサービスです。

## 仕組み

```
音声ファイル → ffmpeg（WAV変換） → basic-pitch（音符検出）
→ LilyPond（楽譜組版） → ピアノPDF + ギターPDF
```

---

## セットアップ（ローカル）

### 必要なもの

| ツール | インストール方法 |
|--------|----------------|
| Python 3.11+ | https://python.org |
| ffmpeg | `brew install ffmpeg` (Mac) / `apt install ffmpeg` (Linux) |
| LilyPond | https://lilypond.org/download.html |

### 手順

```bash
cd suno-sheet-music

# Python依存ライブラリのインストール
pip install -r backend/requirements.txt

# サーバー起動
cd backend
python main.py
```

ブラウザで http://localhost:8000 を開く。

---

## セットアップ（Docker）

```bash
cd suno-sheet-music
docker-compose up --build
```

ブラウザで http://localhost:8000 を開く。

---

## 使い方

1. Suno AIでダウンロードした楽曲ファイル（MP3/WAV/M4A など）をドラッグ＆ドロップ
2. 曲名を入力（任意）
3. 「楽譜を生成する」をクリック
4. 処理完了後、**ピアノ譜PDF** と **ギター譜PDF** をダウンロード

---

## 対応フォーマット

- 入力: `.mp3`, `.wav`, `.m4a`, `.ogg`, `.flac`, `.aac`（最大 50 MB）
- 出力: PDF（ピアノ用・ギター用）

## 注意点

- AI音源の自動採譜のため、複雑な和音や打楽器が混在する場合は精度に限界があります
- 初回起動時は basic-pitch のモデルダウンロードが発生します（約 100 MB）
- 長い曲（3分以上）は処理に 30〜60 秒程度かかります
