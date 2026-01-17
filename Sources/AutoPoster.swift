import Foundation

/// 自動投稿管理クラス
class AutoPoster {
    private let api: LinkedInAPI
    private let contentGenerator: ContentGenerator
    private var scheduledPosts: [ScheduledPost] = []
    private var timer: Timer?

    init(api: LinkedInAPI, contentGenerator: ContentGenerator) {
        self.api = api
        self.contentGenerator = contentGenerator
    }

    /// 即座に投稿
    func postNow(content: String, authorId: String) async throws -> PostResponse {
        let postContent = PostContent(authorId: authorId, text: content)
        let response = try await api.createPost(content: postContent)
        print("✅ 投稿が完了しました: \(response.id)")
        return response
    }

    /// スケジュール投稿を追加
    func schedulePost(
        content: String,
        authorId: String,
        scheduledDate: Date
    ) {
        let scheduledPost = ScheduledPost(
            id: UUID(),
            content: content,
            authorId: authorId,
            scheduledDate: scheduledDate
        )

        scheduledPosts.append(scheduledPost)
        scheduledPosts.sort { $0.scheduledDate < $1.scheduledDate }

        print("📅 投稿をスケジュールしました: \(scheduledDate)")
    }

    /// スケジュールされた投稿を実行
    func startScheduler() {
        timer?.invalidate()

        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task {
                await self?.checkAndPostScheduled()
            }
        }

        print("⏰ スケジューラーを開始しました")
    }

    /// スケジューラーを停止
    func stopScheduler() {
        timer?.invalidate()
        timer = nil
        print("⏸️ スケジューラーを停止しました")
    }

    /// スケジュールされた投稿をチェックして実行
    private func checkAndPostScheduled() async {
        let now = Date()
        let postsToExecute = scheduledPosts.filter { $0.scheduledDate <= now }

        for post in postsToExecute {
            do {
                let postContent = PostContent(authorId: post.authorId, text: post.content)
                let response = try await api.createPost(content: postContent)
                print("✅ スケジュール投稿が完了: \(response.id)")

                // 投稿済みのものを削除
                if let index = scheduledPosts.firstIndex(where: { $0.id == post.id }) {
                    scheduledPosts.remove(at: index)
                }
            } catch {
                print("❌ 投稿エラー: \(error.localizedDescription)")
            }
        }
    }

    /// スケジュールされた投稿一覧を取得
    func getScheduledPosts() -> [ScheduledPost] {
        return scheduledPosts
    }

    /// スケジュールをキャンセル
    func cancelScheduledPost(id: UUID) {
        if let index = scheduledPosts.firstIndex(where: { $0.id == id }) {
            scheduledPosts.remove(at: index)
            print("🗑️ スケジュールをキャンセルしました")
        }
    }

    /// 複数の投稿を一括スケジュール
    func bulkSchedule(
        topics: [String],
        template: ContentGenerator.PostTemplate,
        authorId: String,
        startDate: Date,
        interval: TimeInterval
    ) {
        var currentDate = startDate

        for topic in topics {
            let content = contentGenerator.generatePost(
                topic: topic,
                template: template
            )

            schedulePost(
                content: content,
                authorId: authorId,
                scheduledDate: currentDate
            )

            currentDate = currentDate.addingTimeInterval(interval)
        }

        print("📦 \(topics.count)件の投稿を一括スケジュールしました")
    }
}

// MARK: - Models

struct ScheduledPost: Identifiable {
    let id: UUID
    let content: String
    let authorId: String
    let scheduledDate: Date
}

// MARK: - Helper Extensions

extension Date {
    /// 人間が読みやすい形式で日付を表示
    func formatted() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: self)
    }
}
