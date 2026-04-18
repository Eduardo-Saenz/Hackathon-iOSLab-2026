import Foundation

final class AppPreferences {
    // MARK: - Keys

    private enum Keys {
        static let isAuthenticated = "app.isAuthenticated"
        static let hasCompletedOnboarding = "app.hasCompletedOnboarding"
        static let diagnosticsVisible = "app.diagnosticsVisible"
        static let notificationEnabled = "settings.notificationEnabled"
        static let selectedGoalIDs = "onboarding.selectedGoalIDs"
        static let streakDays = "progress.streakDays"
        static let lastCompletedActionsDate = "progress.lastCompletedActionsDate"
        static let completedActionIDs = "progress.completedActionIDs"
        static let completedActionIDsDate = "progress.completedActionIDsDate"
        static let userEmail = "auth.userEmail"
        static let chatSessionId = "chat.sessionId"
        static let cachedUserName = "user.cachedName"
        static let actionSessionId = "actions.sessionId"
    }

    // MARK: - Shared

    static let shared = AppPreferences()

    // MARK: - Dependencies

    private let defaults: UserDefaults

    // MARK: - Init

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Stored Values

    var isAuthenticated: Bool {
        get { defaults.bool(forKey: Keys.isAuthenticated) }
        set { defaults.set(newValue, forKey: Keys.isAuthenticated) }
    }

    var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: Keys.hasCompletedOnboarding) }
        set { defaults.set(newValue, forKey: Keys.hasCompletedOnboarding) }
    }

    var diagnosticsVisible: Bool {
        get { defaults.bool(forKey: Keys.diagnosticsVisible) }
        set { defaults.set(newValue, forKey: Keys.diagnosticsVisible) }
    }

    var notificationEnabled: Bool {
        get {
            if defaults.object(forKey: Keys.notificationEnabled) == nil {
                return true
            }
            return defaults.bool(forKey: Keys.notificationEnabled)
        }
        set { defaults.set(newValue, forKey: Keys.notificationEnabled) }
    }

    var selectedGoalIDs: [String] {
        get { defaults.stringArray(forKey: Keys.selectedGoalIDs) ?? [] }
        set { defaults.set(newValue, forKey: Keys.selectedGoalIDs) }
    }

    var streakDays: Int {
        get { defaults.integer(forKey: Keys.streakDays) }
        set { defaults.set(max(newValue, 0), forKey: Keys.streakDays) }
    }

    var lastCompletedActionsDate: Date? {
        get { defaults.object(forKey: Keys.lastCompletedActionsDate) as? Date }
        set { defaults.set(newValue, forKey: Keys.lastCompletedActionsDate) }
    }

    var completedActionIDs: [String] {
        get { defaults.stringArray(forKey: Keys.completedActionIDs) ?? [] }
        set { defaults.set(newValue, forKey: Keys.completedActionIDs) }
    }

    var completedActionIDsDate: Date? {
        get { defaults.object(forKey: Keys.completedActionIDsDate) as? Date }
        set { defaults.set(newValue, forKey: Keys.completedActionIDsDate) }
    }

    var userEmail: String? {
        get { defaults.string(forKey: Keys.userEmail) }
        set { defaults.set(newValue, forKey: Keys.userEmail) }
    }

    var chatSessionId: String? {
        get { defaults.string(forKey: Keys.chatSessionId) }
        set { defaults.set(newValue, forKey: Keys.chatSessionId) }
    }

    var cachedUserName: String? {
        get { defaults.string(forKey: Keys.cachedUserName) }
        set { defaults.set(newValue, forKey: Keys.cachedUserName) }
    }

    var actionSessionId: String? {
        get { defaults.string(forKey: Keys.actionSessionId) }
        set { defaults.set(newValue, forKey: Keys.actionSessionId) }
    }
}
