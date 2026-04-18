import Foundation

protocol UserServiceProtocol {
    func getMe() async throws -> UserMe
    func patchMe(_ body: PatchUserBody) async throws -> UserMe
    func getStreak() async throws -> StreakBundle
}

struct UserAPIService: UserServiceProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    func getMe() async throws -> UserMe {
        try await apiClient.send(.usersMe)
    }

    func patchMe(_ body: PatchUserBody) async throws -> UserMe {
        let encoder = JSONEncoder()
        let data = try encoder.encode(body)
        return try await apiClient.send(.patchUsersMe(body: data))
    }

    func getStreak() async throws -> StreakBundle {
        try await apiClient.send(.userStreak)
    }
}

struct MockUserService: UserServiceProtocol {
    func getMe() async throws -> UserMe {
        UserMe(
            id: "mock-user",
            clerkUserId: nil,
            appleSub: nil,
            googleSub: nil,
            email: "usuario@demo.com",
            name: "Edu",
            onboardingCompleted: true,
            timezone: "America/Mexico_City",
            preferredTone: "calm",
            goals: ["sleep", "steps", "energy"],
            createdAt: nil,
            updatedAt: nil
        )
    }

    func patchMe(_ body: PatchUserBody) async throws -> UserMe {
        try await getMe()
    }

    func getStreak() async throws -> StreakBundle {
        StreakBundle(
            dailyUse: StreakDetail(current: 5, longest: 12),
            actionCompletion: StreakDetail(current: 3, longest: 8)
        )
    }
}
