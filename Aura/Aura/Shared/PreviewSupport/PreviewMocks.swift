import Foundation

enum PreviewMocks {
    static let actionsService = MockActionsService()
    static let emotionsService = MockEmotionsService()
    static let userService = MockUserService()
    static let dailyBriefService = MockDailyBriefService()
    static let coachService = MockCoachService()
    static let healthDataProvider = MockHealthDataProvider()

    static let sampleActions: [MicroAction] = [
        .init(
            id: "1",
            title: "10-minute walk",
            description: "Take a light walk after lunch.",
            category: "steps",
            difficulty: "easy",
            estimatedMinutes: 10,
            justification: "A short walk helps close your step gap."
        )
    ]

    static func appPreferences() -> AppPreferences {
        let suiteName = "Aura.Preview.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        return AppPreferences(defaults: defaults)
    }

    static func homeViewModel() -> HomeViewModel {
        HomeViewModel(
            healthKitManager: HealthKitManager(),
            healthDataProvider: healthDataProvider,
            fallbackHealthDataProvider: healthDataProvider,
            actionsService: actionsService,
            userService: userService,
            dailyBriefService: dailyBriefService,
            emotionsService: emotionsService,
            appPreferences: appPreferences()
        )
    }

    static func coachViewModel() -> CoachViewModel {
        CoachViewModel(
            coachService: coachService,
            healthDataProvider: healthDataProvider,
            appPreferences: appPreferences(),
            isRuntimeService: false
        )
    }

    static func progressViewModel() -> ProgressScreenViewModel {
        ProgressScreenViewModel(
            dailyBriefService: dailyBriefService,
            emotionsService: emotionsService,
            userService: userService,
            healthDataProvider: healthDataProvider
        )
    }

    static func onboardingViewModel() -> OnboardingViewModel {
        OnboardingViewModel(
            appPreferences: appPreferences(),
            userService: userService
        )
    }
}
