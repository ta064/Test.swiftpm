# LinkedIn API セットアップガイド

## 1. LinkedIn アプリケーションの作成

### ステップ 1: LinkedIn Developers にアクセス

1. [LinkedIn Developers](https://www.linkedin.com/developers/) にアクセス
2. LinkedInアカウントでログイン
3. 「Create app」をクリック

### ステップ 2: アプリケーション情報を入力

- **App name**: アプリケーション名（例: LinkedIn Auto Poster）
- **LinkedIn Page**: 会社ページまたは個人ページを選択
- **App logo**: アプリケーションのロゴ（任意）
- **Legal agreement**: 利用規約に同意

### ステップ 3: 製品の追加

アプリダッシュボードから以下の製品を追加：

1. **Share on LinkedIn** - 投稿を作成するために必要
2. **Sign In with LinkedIn** - 認証のために必要

### ステップ 4: 認証設定

**Auth** タブで以下を設定：

- **Redirect URLs**: OAuth認証後のリダイレクト先
  ```
  http://localhost:3000/callback
  ```

- **Client ID**: 自動生成されます（メモしておく）
- **Client Secret**: 自動生成されます（メモしておく）

## 2. OAuth 2.0 認証フロー

### 方法A: 3-legged OAuth フロー（推奨）

```bash
# ステップ1: 認証URLを生成
https://www.linkedin.com/oauth/v2/authorization?response_type=code&client_id={YOUR_CLIENT_ID}&redirect_uri={YOUR_REDIRECT_URI}&scope=w_member_social%20r_liteprofile

# ステップ2: ブラウザで上記URLにアクセスし、認証
# 認証後、リダイレクトURLに認証コードが返される

# ステップ3: 認証コードをアクセストークンに交換
curl -X POST https://www.linkedin.com/oauth/v2/accessToken \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d 'grant_type=authorization_code' \
  -d 'code={AUTHORIZATION_CODE}' \
  -d 'client_id={YOUR_CLIENT_ID}' \
  -d 'client_secret={YOUR_CLIENT_SECRET}' \
  -d 'redirect_uri={YOUR_REDIRECT_URI}'
```

レスポンス例:
```json
{
  "access_token": "AQV8...",
  "expires_in": 5184000,
  "refresh_token": "AQW7...",
  "refresh_token_expires_in": 31536000
}
```

### 方法B: 開発用トークン（簡易版）

開発・テスト用には、LinkedIn Developersの「Auth」タブから直接トークンを生成できます：

1. アプリダッシュボードの「Auth」タブを開く
2. 「Generate token」をクリック
3. 必要な権限を選択
4. トークンをコピー

⚠️ **注意**: 開発用トークンは60日で期限切れになります

## 3. 必要な権限（Scopes）

投稿機能に必要な権限：

- `r_liteprofile` - プロフィール情報の読み取り
- `r_emailaddress` - メールアドレスの読み取り（任意）
- `w_member_social` - 投稿の作成

権限のリクエスト方法:
```
scope=r_liteprofile%20w_member_social
```

## 4. Person URN（著者ID）の取得

アクセストークン取得後、著者IDを取得：

```bash
curl -X GET 'https://api.linkedin.com/v2/me' \
  -H 'Authorization: Bearer {ACCESS_TOKEN}'
```

レスポンス例:
```json
{
  "id": "1234567890",
  "firstName": {
    "localized": {
      "ja_JP": "太郎"
    }
  },
  "lastName": {
    "localized": {
      "ja_JP": "山田"
    }
  }
}
```

**著者ID**: `id` フィールドの値を使用（例: "1234567890"）

## 5. API制限

### レート制限

- **投稿API**: 100リクエスト/日/ユーザー
- **プロフィールAPI**: 1000リクエスト/日/アプリ

### 投稿制限

- 1日あたりの投稿数: 制限あり（具体的な数値は非公開）
- 同じコンテンツの重複投稿: スパムとして検出される可能性

## 6. 本番環境への移行

### アプリケーションのレビュー

本番環境で使用するには、LinkedInによるアプリレビューが必要：

1. アプリダッシュボードで「Request verification」をクリック
2. 使用目的とユースケースを説明
3. プライバシーポリシーとサービス利用規約のURLを提供
4. レビュー承認を待つ（通常1〜2週間）

### プライバシーとコンプライアンス

- LinkedInの[API利用規約](https://legal.linkedin.com/api-terms-of-use)を遵守
- ユーザーデータの適切な取り扱い
- スパム投稿の禁止

## 7. トークンのリフレッシュ

アクセストークンの有効期限が切れた場合：

```bash
curl -X POST https://www.linkedin.com/oauth/v2/accessToken \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d 'grant_type=refresh_token' \
  -d 'refresh_token={REFRESH_TOKEN}' \
  -d 'client_id={YOUR_CLIENT_ID}' \
  -d 'client_secret={YOUR_CLIENT_SECRET}'
```

## 8. 環境変数の設定

### .env ファイル

```bash
# LinkedIn API認証情報
export LINKEDIN_ACCESS_TOKEN="your_access_token_here"
export LINKEDIN_AUTHOR_ID="your_person_id_here"

# オプション: OAuth設定（自動リフレッシュ用）
export LINKEDIN_CLIENT_ID="your_client_id"
export LINKEDIN_CLIENT_SECRET="your_client_secret"
export LINKEDIN_REFRESH_TOKEN="your_refresh_token"
```

### 読み込み

```bash
source .env
```

## 9. トラブルシューティング

### エラー: "Insufficient permissions"

**原因**: 必要な権限がない

**解決策**:
1. アプリに製品（Share on LinkedIn）が追加されているか確認
2. OAuth認証時に正しいscopeを指定しているか確認

### エラー: "Invalid token"

**原因**: トークンが期限切れまたは無効

**解決策**:
1. refresh_tokenを使って新しいアクセストークンを取得
2. 再度OAuth認証フローを実行

### エラー: "Daily rate limit exceeded"

**原因**: 1日のAPI呼び出し制限を超過

**解決策**:
1. 24時間待つ
2. リクエスト頻度を減らす
3. キャッシュを活用する

## 10. セキュリティベストプラクティス

1. **トークンの保管**
   - 環境変数またはシークレット管理ツールを使用
   - コードにハードコードしない
   - .gitignoreに.envを追加

2. **HTTPS使用**
   - 本番環境では必ずHTTPSを使用
   - リダイレクトURLもHTTPSで設定

3. **トークンの定期更新**
   - refresh_tokenを使って定期的に更新
   - 期限切れ前に自動更新する仕組みを実装

## 参考リンク

- [LinkedIn API Documentation](https://docs.microsoft.com/en-us/linkedin/)
- [LinkedIn Developers](https://www.linkedin.com/developers/)
- [OAuth 2.0 Guide](https://docs.microsoft.com/en-us/linkedin/shared/authentication/authentication)
- [Share on LinkedIn API](https://docs.microsoft.com/en-us/linkedin/consumer/integrations/self-serve/share-on-linkedin)
