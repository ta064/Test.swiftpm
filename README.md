# LinkedIn Auto Post Tool

LinkedInの投稿コンテンツを自動生成し、スケジュール投稿できるSwiftツールです。

## 機能

### 1. 投稿コンテンツ自動生成
- 複数のテンプレートから選択可能
- カスタマイズ可能なハッシュタグ
- 日本語・英語対応

### 2. テンプレート
- **技術Tip** (.techTip) - 技術的な知見の共有
- **成果報告** (.achievement) - プロジェクトの成功や達成
- **業界インサイト** (.industryInsight) - 業界動向や考察
- **個人の成長** (.personalGrowth) - 学びや成長の記録
- **チームの成功** (.teamCelebration) - チームでの達成
- **製品アップデート** (.productUpdate) - 新機能やリリース情報

### 3. 自動投稿機能
- 即座に投稿
- スケジュール投稿
- 一括スケジュール投稿
- スケジュール管理（追加・削除・一覧表示）

### 4. OAuth 2.0認証
- インタラクティブな認証フロー
- トークンの自動リフレッシュ
- 安全な認証情報管理

### 5. CLIツール
- コマンドラインから簡単に投稿
- スケジュール管理
- 設定ガイド

## クイックスタート

### 1. OAuth認証（推奨）

```bash
# Client IDとSecretを環境変数に設定
export LINKEDIN_CLIENT_ID="your_client_id"
export LINKEDIN_CLIENT_SECRET="your_client_secret"

# OAuth認証を実行
swift run auth
```

ブラウザで認証を完了すると、自動的にトークンと著者IDが設定されます。

### 2. すぐに投稿

```bash
# 技術Tipを投稿
swift run post -t "Swiftの新機能について学びました" -template techTip

# 成果報告を投稿
swift run post -t "新しいアプリをリリースしました" -template achievement
```

### 3. スケジュール投稿

```bash
# 24時間後に投稿
swift run schedule -t "週末の振り返り" -date 24
```

## 詳細セットアップ

### 1. LinkedIn API認証情報の取得

1. [LinkedIn Developers](https://www.linkedin.com/developers/) にアクセス
2. アプリケーションを作成
3. 以下の製品を追加:
   - **Share on LinkedIn** (投稿作成用)
   - **Sign In with LinkedIn** (認証用)
4. 必要な権限:
   - `w_member_social` (投稿作成用)
   - `r_liteprofile` (プロフィール読み取り用)

詳細な手順は [`docs/REQUIRED_INFO.md`](docs/REQUIRED_INFO.md) を参照してください。

### 2. 環境変数の設定

`.env`ファイルを作成して以下を設定:

```bash
export LINKEDIN_ACCESS_TOKEN="your_access_token_here"
export LINKEDIN_AUTHOR_ID="your_person_urn_here"
```

著者ID (Person URN) の取得方法:
```bash
curl -X GET 'https://api.linkedin.com/v2/me' \
  -H 'Authorization: Bearer YOUR_ACCESS_TOKEN'
```

レスポンスの`id`フィールドの値を使用してください。

### 3. ビルドと実行

```bash
# 環境変数を読み込み
source .env

# ビルド
swift build

# 実行
swift run
```

## 使用方法

### CLIコマンド

```bash
# ヘルプを表示
swift run help

# OAuth認証
swift run auth

# 即座に投稿
swift run post -t "投稿内容" -template techTip

# カスタムハッシュタグで投稿
swift run post -t "新機能リリース" -hashtags "#Release,#Update,#New"

# スケジュール投稿（24時間後）
swift run schedule -t "週末の振り返り" -date 24

# セットアップガイドを表示
swift run setup
```

利用可能なテンプレート:
- `techTip` - 技術Tip
- `achievement` - 成果報告
- `industryInsight` - 業界インサイト
- `personalGrowth` - 個人の成長
- `teamCelebration` - チームの成功
- `productUpdate` - 製品アップデート

### プログラムでの使用

```swift
import Foundation

// 初期化
let api = LinkedInAPI(accessToken: "your_access_token")
let contentGenerator = ContentGenerator()
let autoPoster = AutoPoster(api: api, contentGenerator: contentGenerator)

// 1. コンテンツ生成
let content = contentGenerator.generatePost(
    topic: "SwiftのAsync/Awaitを使った非同期処理",
    template: .techTip
)

// 2. 即座に投稿
Task {
    try await autoPoster.postNow(
        content: content,
        authorId: "your_author_id"
    )
}
```

### スケジュール投稿

```swift
// 翌日の午前10時に投稿をスケジュール
let tomorrow = Calendar.current.date(
    byAdding: .day,
    value: 1,
    to: Date()
)!

autoPoster.schedulePost(
    content: content,
    authorId: "your_author_id",
    scheduledDate: tomorrow
)

// スケジューラーを開始
autoPoster.startScheduler()
```

### 一括スケジュール

```swift
let topics = [
    "Swift 6の新機能",
    "iOS 17のベストプラクティス",
    "モバイルアプリのパフォーマンス最適化"
]

// 毎日1つずつ投稿
autoPoster.bulkSchedule(
    topics: topics,
    template: .techTip,
    authorId: "your_author_id",
    startDate: Date(),
    interval: 86400 // 24時間（秒単位）
)
```

### カスタム投稿

```swift
let customContent = contentGenerator.generateCustomPost(
    mainText: """
    本日、新しいプロジェクトをスタートしました！
    チーム全員で協力して、素晴らしいプロダクトを作り上げていきます。
    """,
    callToAction: "応援よろしくお願いします！",
    hashtags: ["#NewProject", "#Innovation", "#TeamWork"]
)
```

## コードの構造

```
Sources/
├── main.swift              # メインエントリーポイント
├── LinkedInAPI.swift       # LinkedIn API クライアント
├── ContentGenerator.swift  # 投稿コンテンツ生成
├── AutoPoster.swift        # 自動投稿・スケジューリング
└── Configuration.swift     # 設定管理
```

## API制限について

LinkedIn APIには以下の制限があります：

- **投稿数制限**: 1日あたりの投稿数に制限があります
- **レート制限**: API呼び出しには頻度制限があります
- **トークン有効期限**: アクセストークンは60日間有効です

詳細は[LinkedIn API Documentation](https://docs.microsoft.com/en-us/linkedin/)を確認してください。

## セキュリティ

- アクセストークンは絶対に公開しないでください
- `.env`ファイルは`.gitignore`に追加してください
- トークンは定期的に更新することを推奨します
- 本番環境では環境変数やシークレット管理ツールを使用してください

## トラブルシューティング

### 投稿が失敗する

1. アクセストークンが有効か確認
2. 必要な権限が付与されているか確認
3. 著者ID (Person URN) が正しいか確認

### 認証エラー

```bash
# プロフィール情報を取得して確認
curl -X GET 'https://api.linkedin.com/v2/me' \
  -H 'Authorization: Bearer YOUR_ACCESS_TOKEN'
```

## ライセンス

MIT License

## 貢献

プルリクエストを歓迎します！バグ報告や機能要望はIssueで報告してください。

## 注意事項

- このツールはLinkedInの利用規約に従って使用してください
- スパム投稿は禁止されています
- 適切な頻度で投稿を行ってください
