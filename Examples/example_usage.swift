import Foundation

// このファイルは使用例を示すサンプルコードです
// 実際に実行するには、main.swiftに統合するか、別のターゲットとして設定してください

// MARK: - Example 1: 簡単な投稿

func example1_simplePost() async throws {
    let api = LinkedInAPI(accessToken: "your_token")
    let generator = ContentGenerator()
    let poster = AutoPoster(api: api, contentGenerator: generator)

    // コンテンツを生成
    let content = generator.generatePost(
        topic: "新しいSwiftの機能について学びました",
        template: .techTip
    )

    // 投稿
    try await poster.postNow(
        content: content,
        authorId: "your_author_id"
    )
}

// MARK: - Example 2: スケジュール投稿

func example2_scheduledPost() {
    let api = LinkedInAPI(accessToken: "your_token")
    let generator = ContentGenerator()
    let poster = AutoPoster(api: api, contentGenerator: generator)

    // 明日の午前9時に投稿
    var components = DateComponents()
    components.day = 1
    components.hour = 9
    components.minute = 0

    let tomorrow = Calendar.current.date(byAdding: components, to: Date())!

    let content = generator.generatePost(
        topic: "プロジェクトが無事完了しました",
        template: .achievement
    )

    poster.schedulePost(
        content: content,
        authorId: "your_author_id",
        scheduledDate: tomorrow
    )

    // スケジューラーを開始
    poster.startScheduler()

    print("投稿をスケジュールしました: \(tomorrow)")
}

// MARK: - Example 3: 一週間分の投稿を一括スケジュール

func example3_weeklySchedule() {
    let api = LinkedInAPI(accessToken: "your_token")
    let generator = ContentGenerator()
    let poster = AutoPoster(api: api, contentGenerator: generator)

    let weeklyTopics = [
        "月曜日: SwiftUIの新機能",
        "火曜日: iOSアプリのパフォーマンス最適化",
        "水曜日: Combineフレームワークの活用",
        "木曜日: Xcodeデバッグテクニック",
        "金曜日: 今週学んだことのまとめ"
    ]

    // 毎日午前10時に投稿
    var startDate = Calendar.current.date(
        bySettingHour: 10,
        minute: 0,
        second: 0,
        of: Date()
    )!

    poster.bulkSchedule(
        topics: weeklyTopics,
        template: .techTip,
        authorId: "your_author_id",
        startDate: startDate,
        interval: 86400 // 24時間
    )

    poster.startScheduler()

    print("一週間分の投稿をスケジュールしました")
}

// MARK: - Example 4: カスタムコンテンツ

func example4_customContent() async throws {
    let api = LinkedInAPI(accessToken: "your_token")
    let generator = ContentGenerator()
    let poster = AutoPoster(api: api, contentGenerator: generator)

    let customContent = generator.generateCustomPost(
        mainText: """
        🚀 新しいプロジェクトを開始しました！

        AIを活用したモバイルアプリケーションの開発に取り組んでいます。
        ユーザー体験を革新的に改善することを目指しています。

        開発の進捗は定期的に共有していきます。
        """,
        callToAction: "ご意見やアドバイスがあればぜひコメントください！",
        hashtags: ["#AI", "#MobileApp", "#Innovation", "#Swift", "#iOS"]
    )

    try await poster.postNow(
        content: customContent,
        authorId: "your_author_id"
    )
}

// MARK: - Example 5: 複数テンプレートの組み合わせ

func example5_mixedTemplates() {
    let api = LinkedInAPI(accessToken: "your_token")
    let generator = ContentGenerator()
    let poster = AutoPoster(api: api, contentGenerator: generator)

    // 異なるタイプの投稿を組み合わせる
    let posts: [(topic: String, template: ContentGenerator.PostTemplate, delay: TimeInterval)] = [
        ("新機能のリリース", .productUpdate, 0),
        ("開発チームの成果", .teamCelebration, 3600),
        ("技術的な学び", .techTip, 7200),
        ("業界トレンド分析", .industryInsight, 10800)
    ]

    let startDate = Date()

    for post in posts {
        let content = generator.generatePost(
            topic: post.topic,
            template: post.template
        )

        let scheduledDate = startDate.addingTimeInterval(post.delay)

        poster.schedulePost(
            content: content,
            authorId: "your_author_id",
            scheduledDate: scheduledDate
        )
    }

    poster.startScheduler()

    print("\(posts.count)件の投稿をスケジュールしました")
}

// MARK: - Example 6: スケジュール管理

func example6_scheduleManagement() {
    let api = LinkedInAPI(accessToken: "your_token")
    let generator = ContentGenerator()
    let poster = AutoPoster(api: api, contentGenerator: generator)

    // 投稿をスケジュール
    let content = generator.generatePost(
        topic: "テスト投稿",
        template: .techTip
    )

    poster.schedulePost(
        content: content,
        authorId: "your_author_id",
        scheduledDate: Date().addingTimeInterval(3600)
    )

    // スケジュール一覧を確認
    let scheduledPosts = poster.getScheduledPosts()
    print("スケジュール済み投稿数: \(scheduledPosts.count)")

    for post in scheduledPosts {
        print("- \(post.scheduledDate.formatted())")
        print("  内容: \(post.content.prefix(50))...")
    }

    // 特定の投稿をキャンセル
    if let firstPost = scheduledPosts.first {
        poster.cancelScheduledPost(id: firstPost.id)
        print("投稿をキャンセルしました")
    }
}

// MARK: - 実行例

// 非同期関数を実行する場合
// Task {
//     try await example1_simplePost()
// }

// 同期関数を実行する場合
// example2_scheduledPost()
