import Foundation

struct SleepStagesSnapshot {
    let coreHours: Double
    let deepHours: Double
    let remHours: Double
    let awakeHours: Double
}

struct HealthDataSnapshot {
    let stepsToday: Int
    let stepsGoal: Int
    let sleepHoursLastNight: Double
    let sleepGoalHours: Double
    let activeCaloriesToday: Double
    let sleepStages: SleepStagesSnapshot?
    let heartRateAverageToday: Double?
    let restingHeartRate: Double?
}
