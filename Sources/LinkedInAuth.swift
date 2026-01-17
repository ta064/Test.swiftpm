import Foundation

/// LinkedIn OAuth 2.0 認証マネージャー
class LinkedInAuthManager {
    private let clientId: String
    private let clientSecret: String
    private let redirectUri: String

    private var accessToken: String?
    private var refreshToken: String?
    private var tokenExpiryDate: Date?

    init(clientId: String, clientSecret: String, redirectUri: String) {
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.redirectUri = redirectUri
    }

    // MARK: - OAuth Authorization URL

    /// OAuth認証URLを生成
    func getAuthorizationURL(scopes: [String] = ["r_liteprofile", "w_member_social"]) -> URL? {
        var components = URLComponents(string: "https://www.linkedin.com/oauth/v2/authorization")
        components?.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "scope", value: scopes.joined(separator: " "))
        ]

        return components?.url
    }

    // MARK: - Token Exchange

    /// 認証コードをアクセストークンに交換
    func exchangeCodeForToken(code: String) async throws -> TokenResponse {
        let url = URL(string: "https://www.linkedin.com/oauth/v2/accessToken")!

        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "client_secret", value: clientSecret),
            URLQueryItem(name: "redirect_uri", value: redirectUri)
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = components.query?.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AuthError.tokenExchangeFailed
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)

        // トークンを保存
        self.accessToken = tokenResponse.accessToken
        self.refreshToken = tokenResponse.refreshToken
        self.tokenExpiryDate = Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn))

        // 設定に保存
        Configuration.shared.saveAccessToken(tokenResponse.accessToken)

        return tokenResponse
    }

    // MARK: - Token Refresh

    /// アクセストークンをリフレッシュ
    func refreshAccessToken() async throws -> TokenResponse {
        guard let refreshToken = self.refreshToken else {
            throw AuthError.noRefreshToken
        }

        let url = URL(string: "https://www.linkedin.com/oauth/v2/accessToken")!

        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "grant_type", value: "refresh_token"),
            URLQueryItem(name: "refresh_token", value: refreshToken),
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "client_secret", value: clientSecret)
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = components.query?.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AuthError.tokenRefreshFailed
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)

        // トークンを更新
        self.accessToken = tokenResponse.accessToken
        self.tokenExpiryDate = Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn))

        // 設定に保存
        Configuration.shared.saveAccessToken(tokenResponse.accessToken)

        print("✅ アクセストークンをリフレッシュしました")

        return tokenResponse
    }

    // MARK: - Token Validation

    /// トークンが有効かチェック
    func isTokenValid() -> Bool {
        guard let expiryDate = tokenExpiryDate else {
            return false
        }

        // 有効期限の5分前をチェック（余裕を持たせる）
        return Date() < expiryDate.addingTimeInterval(-300)
    }

    /// 必要に応じてトークンをリフレッシュ
    func ensureValidToken() async throws -> String {
        if isTokenValid(), let token = accessToken {
            return token
        }

        // トークンをリフレッシュ
        let response = try await refreshAccessToken()
        return response.accessToken
    }

    // MARK: - Manual Token Setup

    /// 手動でトークンを設定（開発用）
    func setTokensManually(accessToken: String, refreshToken: String? = nil, expiresIn: Int = 5184000) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.tokenExpiryDate = Date().addingTimeInterval(TimeInterval(expiresIn))

        Configuration.shared.saveAccessToken(accessToken)

        print("✅ トークンを手動設定しました")
    }

    /// 現在のアクセストークンを取得
    func getAccessToken() -> String? {
        return accessToken
    }
}

// MARK: - Models

struct TokenResponse: Codable {
    let accessToken: String
    let expiresIn: Int
    let refreshToken: String?
    let refreshTokenExpiresIn: Int?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case refreshTokenExpiresIn = "refresh_token_expires_in"
    }
}

enum AuthError: Error {
    case tokenExchangeFailed
    case tokenRefreshFailed
    case noRefreshToken
    case invalidToken

    var description: String {
        switch self {
        case .tokenExchangeFailed:
            return "認証コードのトークン交換に失敗しました"
        case .tokenRefreshFailed:
            return "トークンのリフレッシュに失敗しました"
        case .noRefreshToken:
            return "リフレッシュトークンが見つかりません"
        case .invalidToken:
            return "無効なトークンです"
        }
    }
}

// MARK: - OAuth Helper

/// OAuth認証フローのヘルパー
class OAuthHelper {
    static let shared = OAuthHelper()

    private init() {}

    /// 簡易OAuthフローを実行（開発用）
    func startSimpleOAuthFlow(clientId: String, clientSecret: String, redirectUri: String) {
        let authManager = LinkedInAuthManager(
            clientId: clientId,
            clientSecret: clientSecret,
            redirectUri: redirectUri
        )

        guard let authURL = authManager.getAuthorizationURL() else {
            print("❌ 認証URLの生成に失敗しました")
            return
        }

        print("""

        ╔═══════════════════════════════════════════════════════╗
        ║     LinkedIn OAuth 認証フロー                        ║
        ╚═══════════════════════════════════════════════════════╝

        ステップ1: 以下のURLをブラウザで開いて認証してください

        \(authURL.absoluteString)

        ステップ2: 認証後、リダイレクトURLのクエリパラメータから
                  'code'を取得してください

        例: http://localhost:3000/callback?code=AQT...&state=...
                                                  ^^^^
                                                  この部分

        ステップ3: 取得したコードで以下を実行:

        Task {
            let authManager = LinkedInAuthManager(
                clientId: "\(clientId)",
                clientSecret: "\(clientSecret)",
                redirectUri: "\(redirectUri)"
            )

            do {
                let tokenResponse = try await authManager.exchangeCodeForToken(
                    code: "YOUR_CODE_HERE"
                )
                print("✅ アクセストークン: \\(tokenResponse.accessToken)")

                // トークンを環境変数に設定
                Configuration.shared.saveAccessToken(tokenResponse.accessToken)
            } catch {
                print("❌ エラー: \\(error)")
            }
        }

        """)
    }

    /// 開発用トークン設定ガイド
    func showDevelopmentTokenGuide() {
        print("""

        ╔═══════════════════════════════════════════════════════╗
        ║     開発用トークン設定ガイド                         ║
        ╚═══════════════════════════════════════════════════════╝

        開発・テスト用には、LinkedIn Developersから直接トークンを
        生成できます：

        1. LinkedIn Developers (https://www.linkedin.com/developers/)
           にアクセス

        2. アプリを選択し「Auth」タブを開く

        3. 「Generate token」をクリック

        4. 必要な権限を選択:
           - r_liteprofile
           - w_member_social

        5. トークンをコピーして環境変数に設定:

           export LINKEDIN_ACCESS_TOKEN="生成されたトークン"

        6. 著者IDを取得:

           curl -X GET 'https://api.linkedin.com/v2/me' \\
             -H 'Authorization: Bearer トークン'

        7. 著者IDを環境変数に設定:

           export LINKEDIN_AUTHOR_ID="取得したID"

        ⚠️  注意: 開発用トークンは60日で期限切れになります

        """)
    }
}
