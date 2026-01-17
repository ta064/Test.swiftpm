import Foundation

/// LinkedIn投稿コンテンツ生成クラス
class ContentGenerator {
    /// 投稿テンプレート
    enum PostTemplate {
        case techTip
        case achievement
        case industryInsight
        case personalGrowth
        case teamCelebration
        case productUpdate

        var hashtagSuggestions: [String] {
            switch self {
            case .techTip:
                return ["#TechTips", "#Programming", "#Development", "#Tech"]
            case .achievement:
                return ["#Achievement", "#Success", "#Milestone", "#Growth"]
            case .industryInsight:
                return ["#Industry", "#Insights", "#Trends", "#Business"]
            case .personalGrowth:
                return ["#PersonalGrowth", "#Learning", "#Development", "#Career"]
            case .teamCelebration:
                return ["#TeamWork", "#Team", "#Success", "#Collaboration"]
            case .productUpdate:
                return ["#ProductUpdate", "#Innovation", "#Product", "#Launch"]
            }
        }
    }

    /// 投稿コンテンツを生成
    func generatePost(
        topic: String,
        template: PostTemplate,
        customHashtags: [String] = [],
        includeEmoji: Bool = true
    ) -> String {
        var content = ""

        // メインコンテンツ
        content += generateMainContent(topic: topic, template: template)
        content += "\n\n"

        // Call to Action
        content += generateCallToAction(template: template)
        content += "\n\n"

        // ハッシュタグ
        let hashtags = customHashtags.isEmpty ? template.hashtagSuggestions : customHashtags
        content += hashtags.joined(separator: " ")

        return content
    }

    /// メインコンテンツを生成
    private func generateMainContent(topic: String, template: PostTemplate) -> String {
        let emoji = getEmoji(for: template)

        switch template {
        case .techTip:
            return """
            \(emoji) Tech Tip: \(topic)

            今日は\(topic)について学んだことをシェアします。
            この知識が皆さんの開発にも役立つことを願っています。
            """

        case .achievement:
            return """
            \(emoji) 達成報告

            \(topic)を達成しました！
            この経験から多くを学び、さらなる成長につながりました。
            """

        case .industryInsight:
            return """
            \(emoji) 業界インサイト

            \(topic)について考察してみました。
            業界の皆さんのご意見もぜひお聞かせください。
            """

        case .personalGrowth:
            return """
            \(emoji) 成長の記録

            \(topic)を通じて成長できました。
            継続的な学びの大切さを改めて実感しています。
            """

        case .teamCelebration:
            return """
            \(emoji) チームの成功

            チームで\(topic)を達成しました！
            素晴らしいメンバーとの協働に感謝です。
            """

        case .productUpdate:
            return """
            \(emoji) 新機能リリース

            \(topic)をリリースしました！
            ユーザーの皆様により良い体験を提供できることを嬉しく思います。
            """
        }
    }

    /// Call to Actionを生成
    private func generateCallToAction(template: PostTemplate) -> String {
        switch template {
        case .techTip:
            return "💭 皆さんはどのように活用していますか？コメントでシェアしてください！"
        case .achievement:
            return "📣 同じような経験をされた方、ぜひお話を聞かせてください！"
        case .industryInsight:
            return "💡 皆さんの意見や経験もぜひコメントで教えてください！"
        case .personalGrowth:
            return "🌱 一緒に成長していきましょう！"
        case .teamCelebration:
            return "🤝 素晴らしいチームワークが成功の鍵です！"
        case .productUpdate:
            return "✨ ぜひお試しいただき、フィードバックをお待ちしています！"
        }
    }

    /// テンプレートに応じた絵文字を取得
    private func getEmoji(for template: PostTemplate) -> String {
        switch template {
        case .techTip:
            return "💻"
        case .achievement:
            return "🎉"
        case .industryInsight:
            return "🔍"
        case .personalGrowth:
            return "📈"
        case .teamCelebration:
            return "👏"
        case .productUpdate:
            return "🚀"
        }
    }

    /// カスタムコンテンツを生成
    func generateCustomPost(
        mainText: String,
        callToAction: String? = nil,
        hashtags: [String] = []
    ) -> String {
        var content = mainText

        if let cta = callToAction {
            content += "\n\n\(cta)"
        }

        if !hashtags.isEmpty {
            content += "\n\n\(hashtags.joined(separator: " "))"
        }

        return content
    }
}
