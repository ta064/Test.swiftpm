import Foundation

/// アプリケーション設定管理
class Configuration {
    static let shared = Configuration()

    private let userDefaults = UserDefaults.standard
    private let accessTokenKey = "linkedin_access_token"
    private let authorIdKey = "linkedin_author_id"

    private init() {}

    /// アクセストークンを保存
    func saveAccessToken(_ token: String) {
        userDefaults.set(token, forKey: accessTokenKey)
        print("🔑 アクセストークンを保存しました")
    }

    /// アクセストークンを取得
    func getAccessToken() -> String? {
        return userDefaults.string(forKey: accessTokenKey)
    }

    /// 著者IDを保存
    func saveAuthorId(_ id: String) {
        userDefaults.set(id, forKey: authorIdKey)
        print("👤 著者IDを保存しました")
    }

    /// 著者IDを取得
    func getAuthorId() -> String? {
        return userDefaults.string(forKey: authorIdKey)
    }

    /// 設定をクリア
    func clearConfiguration() {
        userDefaults.removeObject(forKey: accessTokenKey)
        userDefaults.removeObject(forKey: authorIdKey)
        print("🗑️ 設定をクリアしました")
    }

    /// 設定が完了しているか確認
    func isConfigured() -> Bool {
        return getAccessToken() != nil && getAuthorId() != nil
    }
}

/// 環境変数から設定を読み込むヘルパー
struct EnvironmentConfig {
    /// 環境変数からアクセストークンを取得
    static func loadAccessToken() -> String? {
        return ProcessInfo.processInfo.environment["LINKEDIN_ACCESS_TOKEN"]
    }

    /// 環境変数から著者IDを取得
    static func loadAuthorId() -> String? {
        return ProcessInfo.processInfo.environment["LINKEDIN_AUTHOR_ID"]
    }

    /// 環境変数から設定を自動ロード
    static func autoLoadConfiguration() {
        let config = Configuration.shared

        if let token = loadAccessToken() {
            config.saveAccessToken(token)
        }

        if let authorId = loadAuthorId() {
            config.saveAuthorId(authorId)
        }

        if config.isConfigured() {
            print("✅ 環境変数から設定を読み込みました")
        } else {
            print("⚠️ 設定が不完全です。環境変数を確認してください")
        }
    }
}
