import Foundation

// MARK: - Request Models

struct GenerateActionsRequest: Codable {
    let userGoals: [String]
    let healthData: HealthDataPayload
    let streakDays: Int?

    enum CodingKeys: String, CodingKey {
        case userGoals = "user_goals"
        case healthData = "health_data"
        case streakDays = "streak_days"
    }
}

struct HealthDataPayload: Codable {
    let stepsToday: Int
    let stepsGoal: Int
    let sleepHoursLastNight: Double
    let sleepGoalHours: Double
    let activeCaloriesToday: Double
    let sleepStages: SleepStagesPayload?
    let heartRateAverageToday: Double?
    let restingHeartRate: Double?

    enum CodingKeys: String, CodingKey {
        case stepsToday = "steps_today"
        case stepsGoal = "steps_goal"
        case sleepHoursLastNight = "sleep_hours_last_night"
        case sleepGoalHours = "sleep_goal_hours"
        case activeCaloriesToday = "active_calories_today"
        case sleepStages = "sleep_stages"
        case heartRateAverageToday = "heart_rate_average_today"
        case restingHeartRate = "resting_heart_rate"
    }
}

struct SleepStagesPayload: Codable {
    let coreHours: Double
    let deepHours: Double
    let remHours: Double
    let awakeHours: Double

    enum CodingKeys: String, CodingKey {
        case coreHours = "core_hours"
        case deepHours = "deep_hours"
        case remHours = "rem_hours"
        case awakeHours = "awake_hours"
    }
}

// MARK: - Response Models

struct GenerateActionsResponse: Codable {
    let microactions: [MicroAction]
    let motivationMessage: String
    let focusArea: String

    enum CodingKeys: String, CodingKey {
        case microactions
        case motivationMessage = "motivation_message"
        case focusArea = "focus_area"
    }
}

struct MicroAction: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let category: String
    let difficulty: String
    let estimatedMinutes: Int
    let justification: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case category
        case difficulty
        case estimatedMinutes = "estimated_minutes"
        case justification
    }
}
