# LinkedIn API連携に必要な情報

このツールをLinkedIn APIと連携させるために必要な情報を説明します。

## 📋 必要な情報一覧

### 1. **アクセストークン** (LINKEDIN_ACCESS_TOKEN)
- LinkedIn APIを呼び出すための認証トークン
- 有効期限: 60日間（デフォルト）
- 用途: 投稿作成、プロフィール取得

### 2. **著者ID** (LINKEDIN_AUTHOR_ID)
- LinkedInのPerson URN（ユーザー識別子）
- 形式: 数字の文字列（例: "1234567890"）
- 用途: 投稿の作成者を指定

### 3. **Client ID** (オプション - OAuth用)
- LinkedInアプリケーションのクライアントID
- 用途: OAuth 2.0認証フロー

### 4. **Client Secret** (オプション - OAuth用)
- LinkedInアプリケーションのクライアントシークレット
- 用途: OAuth 2.0認証フロー

## 🔧 情報の取得方法

### ステップ1: LinkedInアプリケーションの作成

1. **LinkedIn Developersにアクセス**
   ```
   https://www.linkedin.com/developers/
   ```

2. **新規アプリを作成**
   - 「Create app」をクリック
   - アプリ名を入力（例: "My Auto Poster"）
   - LinkedIn Pageを選択（個人または会社ページ）
   - ロゴをアップロード（オプション）
   - 利用規約に同意

3. **アプリが作成されました！**
   - アプリダッシュボードに移動します

### ステップ2: 製品の追加と権限の取得

1. **「Products」タブを開く**

2. **必要な製品を追加**
   - **Share on LinkedIn** - 投稿作成に必須
   - **Sign In with LinkedIn** - 認証に必須

3. **「Auth」タブで確認**
   - Client ID: 自動生成されます
   - Client Secret: 「Show」をクリックして確認

### ステップ3: アクセストークンの取得

#### 方法A: 開発用トークン（簡単・推奨）

1. **アプリダッシュボード > Auth タブ**

2. **「Generate token」をクリック**

3. **必要な権限を選択**
   - `r_liteprofile` - プロフィール情報の読み取り
   - `w_member_social` - 投稿の作成

4. **トークンをコピー**
   ```
   例: AQVxyz...（長い文字列）
   ```

5. **環境変数に設定**
   ```bash
   export LINKEDIN_ACCESS_TOKEN="AQVxyz..."
   ```

⚠️ **注意**: 開発用トークンは60日で期限切れになります

#### 方法B: OAuth 2.0フロー（本番用）

1. **リダイレクトURLを設定**
   - Auth タブ > Redirect URLs
   - `http://localhost:3000/callback` を追加

2. **このツールでOAuth認証を実行**
   ```bash
   # Client IDとSecretを環境変数に設定
   export LINKEDIN_CLIENT_ID="your_client_id"
   export LINKEDIN_CLIENT_SECRET="your_client_secret"

   # OAuth認証を実行
   swift run auth
   ```

3. **ブラウザで認証**
   - 表示されたURLをブラウザで開く
   - LinkedInにログインして許可
   - 認証コードを入力

4. **自動的にトークンが保存されます**

### ステップ4: 著者IDの取得

トークン取得後、以下のコマンドで著者IDを取得：

```bash
# curlを使用
curl -X GET 'https://api.linkedin.com/v2/me' \
  -H 'Authorization: Bearer YOUR_ACCESS_TOKEN'
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

**著者ID**: `"id"` フィールドの値（この例では `"1234567890"`）

環境変数に設定:
```bash
export LINKEDIN_AUTHOR_ID="1234567890"
```

## 💾 .env ファイルの作成

すべての情報を`.env`ファイルに保存（推奨）:

```bash
# .envファイルを作成
cat > .env << 'EOF'
# LinkedIn API認証情報
export LINKEDIN_ACCESS_TOKEN="your_access_token_here"
export LINKEDIN_AUTHOR_ID="your_author_id_here"

# OAuth設定（オプション）
export LINKEDIN_CLIENT_ID="your_client_id"
export LINKEDIN_CLIENT_SECRET="your_client_secret"
EOF

# 環境変数を読み込み
source .env
```

⚠️ **セキュリティ**: `.env`ファイルは`.gitignore`に追加してコミットしないでください

## ✅ 設定の確認

### 1. 環境変数が設定されているか確認

```bash
echo $LINKEDIN_ACCESS_TOKEN
echo $LINKEDIN_AUTHOR_ID
```

### 2. APIが正しく動作するかテスト

```bash
# プロフィール情報を取得
curl -X GET 'https://api.linkedin.com/v2/me' \
  -H "Authorization: Bearer $LINKEDIN_ACCESS_TOKEN"
```

成功すれば、プロフィール情報が返されます。

### 3. ツールを実行

```bash
# デモモードで実行
swift run

# CLIモードで投稿
swift run post -t "テスト投稿" -template techTip
```

## 📊 情報の整理チェックリスト

- [ ] LinkedInアプリケーションを作成した
- [ ] 「Share on LinkedIn」製品を追加した
- [ ] アクセストークンを取得した
- [ ] 著者IDを取得した
- [ ] 環境変数を設定した（または.envファイルを作成した）
- [ ] APIテストが成功した
- [ ] ツールが正常に動作することを確認した

## 🔄 トークンの更新

### 開発用トークンの場合

有効期限（60日）が切れたら、再度「Generate token」で新しいトークンを取得します。

### OAuth トークンの場合

Refresh Tokenを使って自動更新できます（実装済み）:

```swift
let authManager = LinkedInAuthManager(
    clientId: "your_client_id",
    clientSecret: "your_client_secret",
    redirectUri: "http://localhost:3000/callback"
)

// トークンをリフレッシュ
let newToken = try await authManager.refreshAccessToken()
```

## 🆘 トラブルシューティング

### エラー: "Invalid access token"

**原因**: トークンが無効または期限切れ

**解決策**:
```bash
# 新しいトークンを生成
swift run auth
```

### エラー: "Insufficient permissions"

**原因**: 必要な権限がない

**解決策**:
1. LinkedIn Developers > アプリ > Products
2. 「Share on LinkedIn」が追加されているか確認
3. トークン生成時に `w_member_social` 権限を選択

### エラー: "Could not authenticate you"

**原因**: Client IDまたはSecretが間違っている

**解決策**:
1. LinkedIn Developers > Auth タブで確認
2. 環境変数を再設定

## 📚 参考リンク

- [LinkedIn Developers](https://www.linkedin.com/developers/)
- [LinkedIn API Documentation](https://docs.microsoft.com/en-us/linkedin/)
- [OAuth 2.0 Guide](https://docs.microsoft.com/en-us/linkedin/shared/authentication/authentication)
- [Share API Documentation](https://docs.microsoft.com/en-us/linkedin/consumer/integrations/self-serve/share-on-linkedin)

## 📞 サポート

問題が解決しない場合:

1. `docs/API_SETUP.md` を参照
2. `swift run setup` でセットアップガイドを表示
3. `swift run help` でコマンド一覧を確認
4. LinkedInのAPI制限を確認（1日100投稿まで）
