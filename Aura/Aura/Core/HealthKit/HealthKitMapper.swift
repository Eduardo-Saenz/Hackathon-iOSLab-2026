import Foundation

enum HealthKitMapper {
    static func mapToPayload(_ snapshot: HealthDataSnapshot) -> HealthDataPayload {
        HealthDataPayload(
            stepsToday: snapshot.stepsToday,
            stepsGoal: snapshot.stepsGoal,
            sleepHoursLastNight: snapshot.sleepHoursLastNight,
            sleepGoalHours: snapshot.sleepGoalHours,
            activeCaloriesToday: snapshot.activeCaloriesToday,
            sleepStages: mapSleepStages(snapshot.sleepStages),
            heartRateAverageToday: snapshot.heartRateAverageToday,
            restingHeartRate: snapshot.restingHeartRate
        )
    }

    private static func mapSleepStages(_ stages: SleepStagesSnapshot?) -> SleepStagesPayload? {
        guard let stages else { return nil }
        return SleepStagesPayload(
            coreHours: stages.coreHours,
            deepHours: stages.deepHours,
            remHours: stages.remHours,
            awakeHours: stages.awakeHours
        )
    }
}
