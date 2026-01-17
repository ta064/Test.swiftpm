import Foundation

/// コマンドラインインターフェース
struct CLI {
    static func run(arguments: [String]) async {
        let command = arguments.count > 1 ? arguments[1] : "help"

        switch command {
        case "auth", "login":
            await handleAuth()

        case "post":
            await handlePost(arguments: Array(arguments.dropFirst(2)))

        case "schedule":
            await handleSchedule(arguments: Array(arguments.dropFirst(2)))

        case "list":
            handleList()

        case "setup":
            handleSetup()

        case "help", "-h", "--help":
            showHelp()

        default:
            print("❌ 不明なコマンド: \(command)")
            print("使用方法: swift run linkedin-poster help")
        }
    }

    // MARK: - Auth Command

    static func handleAuth() async {
        await OAuthCLITool.run()
    }

    // MARK: - Post Command

    static func handlePost(arguments: [String]) async {
        guard let config = loadConfiguration() else { return }

        var topic = ""
        var template: ContentGenerator.PostTemplate = .techTip
        var customHashtags: [String] = []

        // 引数をパース
        var i = 0
        while i < arguments.count {
            let arg = arguments[i]

            switch arg {
            case "-t", "--topic":
                if i + 1 < arguments.count {
                    topic = arguments[i + 1]
                    i += 1
                }

            case "-template", "--template":
                if i + 1 < arguments.count {
                    template = parseTemplate(arguments[i + 1])
                    i += 1
                }

            case "-hashtags", "--hashtags":
                if i + 1 < arguments.count {
                    customHashtags = arguments[i + 1].split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
                    i += 1
                }

            default:
                if topic.isEmpty {
                    topic = arg
                }
            }

            i += 1
        }

        guard !topic.isEmpty else {
            print("❌ トピックを指定してください")
            print("使用例: swift run post -t \"SwiftのAsync/Await\"")
            return
        }

        // コンテンツを生成
        let generator = ContentGenerator()
        let content = generator.generatePost(
            topic: topic,
            template: template,
            customHashtags: customHashtags
        )

        print("\n📝 生成されたコンテンツ:\n")
        print("─────────────────────────────────────")
        print(content)
        print("─────────────────────────────────────\n")

        // 確認
        print("このコンテンツを投稿しますか? (y/n): ", terminator: "")
        if let response = readLine()?.lowercased(), response == "y" || response == "yes" {
            // 投稿実行
            let api = LinkedInAPI(accessToken: config.accessToken)
            let poster = AutoPoster(api: api, contentGenerator: generator)

            do {
                print("\n🚀 投稿中...")
                let response = try await poster.postNow(
                    content: content,
                    authorId: config.authorId
                )
                print("✅ 投稿が完了しました！")
                print("投稿ID: \(response.id)")
            } catch {
                print("❌ 投稿エラー: \(error)")
            }
        } else {
            print("❌ 投稿をキャンセルしました")
        }
    }

    // MARK: - Schedule Command

    static func handleSchedule(arguments: [String]) async {
        guard let config = loadConfiguration() else { return }

        var topic = ""
        var template: ContentGenerator.PostTemplate = .techTip
        var dateString = ""

        // 引数をパース
        var i = 0
        while i < arguments.count {
            let arg = arguments[i]

            switch arg {
            case "-t", "--topic":
                if i + 1 < arguments.count {
                    topic = arguments[i + 1]
                    i += 1
                }

            case "-template", "--template":
                if i + 1 < arguments.count {
                    template = parseTemplate(arguments[i + 1])
                    i += 1
                }

            case "-date", "--date":
                if i + 1 < arguments.count {
                    dateString = arguments[i + 1]
                    i += 1
                }

            default:
                if topic.isEmpty {
                    topic = arg
                }
            }

            i += 1
        }

        guard !topic.isEmpty else {
            print("❌ トピックを指定してください")
            return
        }

        // 日時をパース（簡易版）
        let scheduledDate: Date
        if !dateString.isEmpty {
            // ISO8601形式または相対時間
            if let hours = Int(dateString) {
                scheduledDate = Date().addingTimeInterval(TimeInterval(hours * 3600))
            } else {
                print("❌ 無効な日時形式です。時間数（例: 24）を指定してください")
                return
            }
        } else {
            scheduledDate = Date().addingTimeInterval(3600) // デフォルト: 1時間後
        }

        // コンテンツを生成
        let generator = ContentGenerator()
        let content = generator.generatePost(topic: topic, template: template)

        // スケジュール
        let api = LinkedInAPI(accessToken: config.accessToken)
        let poster = AutoPoster(api: api, contentGenerator: generator)

        poster.schedulePost(
            content: content,
            authorId: config.authorId,
            scheduledDate: scheduledDate
        )

        print("✅ 投稿をスケジュールしました")
        print("投稿予定: \(scheduledDate.formatted())")
    }

    // MARK: - List Command

    static func handleList() {
        print("\n📋 スケジュール済み投稿:\n")
        // TODO: 永続化されたスケジュールを読み込む
        print("（現在、スケジュールはメモリに保持されています）")
    }

    // MARK: - Setup Command

    static func handleSetup() {
        OAuthHelper.shared.showDevelopmentTokenGuide()
    }

    // MARK: - Help Command

    static func showHelp() {
        print("""

        ╔═══════════════════════════════════════════════════════╗
        ║     LinkedIn Auto Post Tool - コマンド一覧           ║
        ╚═══════════════════════════════════════════════════════╝

        認証:
          auth, login              OAuth認証フローを開始

        投稿:
          post [オプション]        即座に投稿
            -t, --topic <text>     投稿トピック
            -template <type>       テンプレートタイプ
            -hashtags <tags>       カスタムハッシュタグ (カンマ区切り)

        スケジュール:
          schedule [オプション]    投稿をスケジュール
            -t, --topic <text>     投稿トピック
            -template <type>       テンプレートタイプ
            -date <hours>          何時間後に投稿するか

        管理:
          list                     スケジュール済み投稿を表示
          setup                    セットアップガイドを表示
          help                     このヘルプを表示

        テンプレートタイプ:
          techTip                  技術Tip
          achievement              成果報告
          industryInsight          業界インサイト
          personalGrowth           個人の成長
          teamCelebration          チームの成功
          productUpdate            製品アップデート

        使用例:

          # OAuth認証
          swift run auth

          # 即座に投稿
          swift run post -t "Swiftの新機能" -template techTip

          # カスタムハッシュタグで投稿
          swift run post -t "プロジェクト完了" -hashtags "#Success,#Team"

          # 24時間後に投稿をスケジュール
          swift run schedule -t "週末の振り返り" -date 24

        環境変数:
          LINKEDIN_ACCESS_TOKEN    アクセストークン
          LINKEDIN_AUTHOR_ID       著者ID
          LINKEDIN_CLIENT_ID       Client ID (OAuth用)
          LINKEDIN_CLIENT_SECRET   Client Secret (OAuth用)

        詳細: README.md または docs/API_SETUP.md を参照

        """)
    }

    // MARK: - Helpers

    private static func loadConfiguration() -> (accessToken: String, authorId: String)? {
        let config = Configuration.shared

        guard let accessToken = config.getAccessToken(),
              let authorId = config.getAuthorId() else {
            print("""

            ⚠️  設定が不完全です

            以下のコマンドでセットアップしてください:
            swift run auth

            または、環境変数を手動で設定:
            export LINKEDIN_ACCESS_TOKEN="your_token"
            export LINKEDIN_AUTHOR_ID="your_id"

            """)
            return nil
        }

        return (accessToken, authorId)
    }

    private static func parseTemplate(_ templateString: String) -> ContentGenerator.PostTemplate {
        switch templateString.lowercased() {
        case "techtip", "tech":
            return .techTip
        case "achievement", "achieve":
            return .achievement
        case "industryinsight", "industry", "insight":
            return .industryInsight
        case "personalgrowth", "growth":
            return .personalGrowth
        case "teamcelebration", "team":
            return .teamCelebration
        case "productupdate", "product":
            return .productUpdate
        default:
            return .techTip
        }
    }
}
