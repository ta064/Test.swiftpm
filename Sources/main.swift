import Foundation

// MARK: - Main Entry Point

// コマンドライン引数を取得
let arguments = CommandLine.arguments

// CLIモードかデモモードかを判定
if arguments.count > 1 {
    // CLIモード
    await CLI.run(arguments: arguments)
    exit(0)
}

// デモモード
print("""
╔═══════════════════════════════════════════════════════╗
║     LinkedIn 自動投稿ツール                          ║
║     LinkedIn Auto Post Tool                          ║
╚═══════════════════════════════════════════════════════╝
""")

// 環境変数から設定を読み込み
EnvironmentConfig.autoLoadConfiguration()

let config = Configuration.shared

// 設定確認
guard config.isConfigured(),
      let accessToken = config.getAccessToken(),
      let authorId = config.getAuthorId() else {
    print("""

    ⚠️  設定が不完全です。以下のいずれかの方法でセットアップしてください:

    【方法1】OAuth認証を使用（推奨）:
    swift run auth

    【方法2】環境変数を手動設定:
    export LINKEDIN_ACCESS_TOKEN="your_access_token"
    export LINKEDIN_AUTHOR_ID="your_author_id"

    【方法3】セットアップガイドを表示:
    swift run setup

    詳細: README.md または docs/API_SETUP.md を参照

    """)
    exit(1)
}

// インスタンス初期化
let api = LinkedInAPI(accessToken: accessToken)
let contentGenerator = ContentGenerator()
let autoPoster = AutoPoster(api: api, contentGenerator: contentGenerator)

// MARK: - サンプル投稿の実行

print("\n📝 投稿サンプルを実行します...\n")

// サンプル1: 技術Tipの投稿
let techTipContent = contentGenerator.generatePost(
    topic: "SwiftのAsync/Awaitを使った非同期処理",
    template: .techTip
)

print("--- サンプル投稿 1: 技術Tip ---")
print(techTipContent)
print("\n")

// サンプル2: 成果報告の投稿
let achievementContent = contentGenerator.generatePost(
    topic: "新しいiOSアプリのリリース",
    template: .achievement
)

print("--- サンプル投稿 2: 成果報告 ---")
print(achievementContent)
print("\n")

// サンプル3: カスタム投稿
let customContent = contentGenerator.generateCustomPost(
    mainText: """
    本日、新しいプロジェクトをスタートしました！

    チーム全員で協力して、素晴らしいプロダクトを作り上げていきます。
    """,
    callToAction: "応援よろしくお願いします！",
    hashtags: ["#NewProject", "#Innovation", "#TeamWork"]
)

print("--- サンプル投稿 3: カスタム ---")
print(customContent)
print("\n")

// MARK: - 使用例のデモンストレーション

print("""
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📚 使用方法
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. 即座に投稿:
   Task {
       try await autoPoster.postNow(
           content: techTipContent,
           authorId: authorId
       )
   }

2. スケジュール投稿:
   let tomorrow = Date().addingTimeInterval(86400)
   autoPoster.schedulePost(
       content: achievementContent,
       authorId: authorId,
       scheduledDate: tomorrow
   )
   autoPoster.startScheduler()

3. 一括スケジュール:
   let topics = [
       "Swift 6の新機能",
       "iOS 17のベストプラクティス",
       "モバイルアプリのパフォーマンス最適化"
   ]

   autoPoster.bulkSchedule(
       topics: topics,
       template: .techTip,
       authorId: authorId,
       startDate: Date(),
       interval: 86400 // 24時間ごと
   )

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚙️  設定管理
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

環境変数:
• LINKEDIN_ACCESS_TOKEN - LinkedInアクセストークン
• LINKEDIN_AUTHOR_ID - 著者ID (Person URN)

設定クリア:
Configuration.shared.clearConfiguration()

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 利用可能なテンプレート
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

• .techTip          - 技術Tip
• .achievement      - 成果報告
• .industryInsight  - 業界インサイト
• .personalGrowth   - 個人の成長
• .teamCelebration  - チームの成功
• .productUpdate    - 製品アップデート

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
""")

// コメントアウト: 実際に投稿する場合は以下のコメントを外してください
/*
Task {
    do {
        print("\n🚀 投稿を実行中...")
        let response = try await autoPoster.postNow(
            content: techTipContent,
            authorId: authorId
        )
        print("✅ 投稿完了! ID: \(response.id)")
    } catch {
        print("❌ エラー: \(error.localizedDescription)")
    }
}
*/

print("\n✨ プログラムを終了します\n")
