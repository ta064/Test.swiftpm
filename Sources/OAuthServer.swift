import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// OAuth認証用の簡易HTTPサーバー
class OAuthCallbackServer {
    private var isRunning = false
    private var receivedCode: String?
    private let port: Int

    init(port: Int = 3000) {
        self.port = port
    }

    /// サーバーを起動してコールバックを待機
    func waitForCallback(timeout: TimeInterval = 300) async throws -> String {
        print("""

        🌐 OAuth コールバックサーバーを起動しました
        リダイレクトURL: http://localhost:\(port)/callback

        ブラウザで認証を完了してください...
        """)

        // タイムアウト設定
        let deadline = Date().addingTimeInterval(timeout)

        // コールバック待機（簡易実装）
        while Date() < deadline {
            if let code = receivedCode {
                print("✅ 認証コードを受信しました")
                return code
            }

            try await Task.sleep(nanoseconds: 1_000_000_000) // 1秒待機
        }

        throw OAuthServerError.timeout
    }

    /// コールバックを手動で設定（テスト用）
    func setCallbackCode(_ code: String) {
        self.receivedCode = code
    }
}

enum OAuthServerError: Error {
    case timeout
    case serverStartFailed

    var description: String {
        switch self {
        case .timeout:
            return "認証のタイムアウト"
        case .serverStartFailed:
            return "サーバーの起動に失敗"
        }
    }
}

// MARK: - Interactive OAuth Flow

/// インタラクティブなOAuth認証フロー
class InteractiveOAuthFlow {
    private let authManager: LinkedInAuthManager
    private let callbackServer: OAuthCallbackServer

    init(clientId: String, clientSecret: String, redirectUri: String = "http://localhost:3000/callback") {
        self.authManager = LinkedInAuthManager(
            clientId: clientId,
            clientSecret: clientSecret,
            redirectUri: redirectUri
        )
        self.callbackServer = OAuthCallbackServer(port: 3000)
    }

    /// 完全な認証フローを実行
    func authenticate() async throws -> TokenResponse {
        // ステップ1: 認証URLを生成
        guard let authURL = authManager.getAuthorizationURL() else {
            throw OAuthServerError.serverStartFailed
        }

        print("""

        ╔═══════════════════════════════════════════════════════╗
        ║     LinkedIn OAuth 認証                              ║
        ╚═══════════════════════════════════════════════════════╝

        以下のURLをブラウザで開いて認証してください:

        \(authURL.absoluteString)

        """)

        // macOSの場合、自動的にブラウザを開く（オプション）
        #if os(macOS)
        if let url = URL(string: authURL.absoluteString) {
            // NSWorkspaceが利用可能な場合のみ
            // NSWorkspace.shared.open(url)
            print("💡 macOSをお使いの場合、上記URLをコピーしてブラウザで開いてください")
        }
        #endif

        // ステップ2: コールバックを待機
        print("\n⏳ 認証コードの入力を待っています...")
        print("リダイレクトURL (http://localhost:3000/callback?code=...) の")
        print("'code' パラメータの値を入力してください:\n")

        // 標準入力からコードを読み取り
        guard let code = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines),
              !code.isEmpty else {
            throw AuthError.invalidToken
        }

        print("\n🔄 トークンを取得中...")

        // ステップ3: トークンを取得
        let tokenResponse = try await authManager.exchangeCodeForToken(code: code)

        print("""

        ✅ 認証に成功しました！

        アクセストークン: \(tokenResponse.accessToken.prefix(20))...
        有効期限: \(tokenResponse.expiresIn)秒 (\(tokenResponse.expiresIn / 86400)日)

        """)

        // 環境変数設定のガイドを表示
        showEnvSetupGuide(token: tokenResponse.accessToken)

        return tokenResponse
    }

    /// 環境変数設定ガイドを表示
    private func showEnvSetupGuide(token: String) {
        print("""

        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        📝 次のステップ: 環境変数を設定
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

        1. アクセストークンを環境変数に設定:

           export LINKEDIN_ACCESS_TOKEN="\(token)"

        2. 著者IDを取得して設定:

           # 著者IDを取得
           curl -X GET 'https://api.linkedin.com/v2/me' \\
             -H 'Authorization: Bearer \(token)'

           # 取得したIDを設定
           export LINKEDIN_AUTHOR_ID="取得したID"

        3. .envファイルに保存（推奨）:

           echo 'export LINKEDIN_ACCESS_TOKEN="\(token)"' >> .env
           echo 'export LINKEDIN_AUTHOR_ID="YOUR_ID_HERE"' >> .env

        4. 環境変数を読み込み:

           source .env

        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

        """)
    }
}

// MARK: - CLI OAuth Tool

/// コマンドラインOAuthツール
struct OAuthCLITool {
    static func run() async {
        print("""

        ╔═══════════════════════════════════════════════════════╗
        ║     LinkedIn OAuth セットアップツール                ║
        ╚═══════════════════════════════════════════════════════╝

        """)

        // 環境変数から認証情報を取得
        guard let clientId = ProcessInfo.processInfo.environment["LINKEDIN_CLIENT_ID"],
              let clientSecret = ProcessInfo.processInfo.environment["LINKEDIN_CLIENT_SECRET"] else {
            print("""

            ⚠️  認証情報が設定されていません

            以下の環境変数を設定してください:

            export LINKEDIN_CLIENT_ID="your_client_id"
            export LINKEDIN_CLIENT_SECRET="your_client_secret"

            Client IDとSecretの取得方法:
            1. https://www.linkedin.com/developers/ にアクセス
            2. アプリを作成または選択
            3. 「Auth」タブからClient IDとSecretを確認

            """)
            return
        }

        // OAuth フローを実行
        let flow = InteractiveOAuthFlow(
            clientId: clientId,
            clientSecret: clientSecret
        )

        do {
            let tokenResponse = try await flow.authenticate()

            // 著者IDを自動取得
            print("📥 著者IDを取得中...")
            let authorId = try await fetchAuthorId(accessToken: tokenResponse.accessToken)

            // 設定を保存
            Configuration.shared.saveAccessToken(tokenResponse.accessToken)
            Configuration.shared.saveAuthorId(authorId)

            print("""

            🎉 セットアップが完了しました！

            アプリケーションを実行できます:
            swift run

            """)

        } catch {
            print("❌ エラー: \(error)")
        }
    }

    /// 著者IDを取得
    private static func fetchAuthorId(accessToken: String) async throws -> String {
        let api = LinkedInAPI(accessToken: accessToken)
        let profile = try await api.getUserProfile()
        return profile.id
    }
}
