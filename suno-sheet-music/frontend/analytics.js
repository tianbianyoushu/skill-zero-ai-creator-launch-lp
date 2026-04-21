// ============================================================
//  AI Gakufu — Google Analytics 4 共通設定
// ============================================================
//
//  GA4の測定IDを変更する場合、以下の GA_ID 変数だけを書き換えてください。
//  全ページが /analytics.js を参照しているため、この1箇所だけで反映されます。
//
//  測定IDの取得方法：
//    1. https://analytics.google.com/ にアクセス
//    2. 管理 → プロパティを作成 → プロパティ名「AI Gakufu」
//    3. データストリーム → ウェブ → URL: https://ai-gakufu.com/
//    4. 発行された「G-XXXXXXXXXX」形式のIDを下に貼り付け
// ============================================================

(function () {
  const GA_ID = 'G-XXXXXXXXXX'; // ← ここだけ置換すればOK

  // プレースホルダのままなら計測タグを読み込まない（開発環境・未設定時の保護）
  if (!GA_ID || GA_ID === 'G-XXXXXXXXXX') return;

  // gtag.js を非同期で読み込み
  const script = document.createElement('script');
  script.async = true;
  script.src = 'https://www.googletagmanager.com/gtag/js?id=' + GA_ID;
  document.head.appendChild(script);

  // dataLayer 初期化と config 送信
  window.dataLayer = window.dataLayer || [];
  window.gtag = function () { window.dataLayer.push(arguments); };
  window.gtag('js', new Date());
  window.gtag('config', GA_ID, {
    anonymize_ip: true,            // IPアノニマイズ（EU法遵守）
    cookie_flags: 'SameSite=None;Secure'
  });
})();
