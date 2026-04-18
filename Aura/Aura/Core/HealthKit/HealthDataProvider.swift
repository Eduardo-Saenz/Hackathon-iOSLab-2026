import Foundation

protocol HealthDataProviding {
    func fetchCurrentSnapshot() async throws -> HealthDataSnapshot
}

struct MockHealthDataProvider: HealthDataProviding {
    func fetchCurrentSnapshot() async throws -> HealthDataSnapshot {
        HealthDataSnapshot(
            stepsToday: 6234,
            stepsGoal: 10000,
            sleepHoursLastNight: 5.8,
            sleepGoalHours: 8.0,
            activeCaloriesToday: 320,
            sleepStages: SleepStagesSnapshot(coreHours: 2.5, deepHours: 1.2, remHours: 2.1, awakeHours: 0.3),
            heartRateAverageToday: 72,
            restingHeartRate: 58
        )
    }
}

@MainActor
final class HealthKitHealthDataProvider: HealthDataProviding {
    private let healthKitManager: HealthKitManaging

    init(healthKitManager: HealthKitManaging) {
        self.healthKitManager = healthKitManager
    }

    func fetchCurrentSnapshot() async throws -> HealthDataSnapshot {
        healthKitManager.refreshAuthorizationState()

        if healthKitManager.authorizationState == .notRequested {
            await healthKitManager.requestAuthorization()
        }

        let summary = try await healthKitManager.fetchDailySummary()
        return HealthDataSnapshot(
            stepsToday: summary.stepsToday,
            stepsGoal: 10000,
            sleepHoursLastNight: summary.sleepHoursLastNight,
            sleepGoalHours: 8.0,
            activeCaloriesToday: summary.activeCaloriesToday,
            sleepStages: nil,
            heartRateAverageToday: nil,
            restingHeartRate: nil
        )
    }
}
