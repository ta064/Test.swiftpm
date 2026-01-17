import Foundation

/// LinkedIn APIクライアント
class LinkedInAPI {
    private let accessToken: String
    private let baseURL = "https://api.linkedin.com/v2"

    init(accessToken: String) {
        self.accessToken = accessToken
    }

    /// ユーザープロフィール情報を取得
    func getUserProfile() async throws -> UserProfile {
        let url = URL(string: "\(baseURL)/me")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw LinkedInError.invalidResponse
        }

        let profile = try JSONDecoder().decode(UserProfile.self, from: data)
        return profile
    }

    /// 投稿を作成
    func createPost(content: PostContent) async throws -> PostResponse {
        let url = URL(string: "\(baseURL)/ugcPosts")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // 投稿データの作成
        let postData = try createPostData(from: content)
        request.httpBody = postData

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw LinkedInError.postFailed
        }

        let postResponse = try JSONDecoder().decode(PostResponse.self, from: data)
        return postResponse
    }

    /// 投稿データを作成
    private func createPostData(from content: PostContent) throws -> Data {
        let postBody: [String: Any] = [
            "author": "urn:li:person:\(content.authorId)",
            "lifecycleState": "PUBLISHED",
            "specificContent": [
                "com.linkedin.ugc.ShareContent": [
                    "shareCommentary": [
                        "text": content.text
                    ],
                    "shareMediaCategory": "NONE"
                ]
            ],
            "visibility": [
                "com.linkedin.ugc.MemberNetworkVisibility": "PUBLIC"
            ]
        ]

        return try JSONSerialization.data(withJSONObject: postBody)
    }
}

// MARK: - Models

struct UserProfile: Codable {
    let id: String
    let firstName: LocalizedString
    let lastName: LocalizedString

    struct LocalizedString: Codable {
        let localized: [String: String]
    }
}

struct PostContent {
    let authorId: String
    let text: String
}

struct PostResponse: Codable {
    let id: String
}

enum LinkedInError: Error {
    case invalidResponse
    case postFailed
    case authenticationFailed

    var description: String {
        switch self {
        case .invalidResponse:
            return "無効なレスポンスです"
        case .postFailed:
            return "投稿に失敗しました"
        case .authenticationFailed:
            return "認証に失敗しました"
        }
    }
}
