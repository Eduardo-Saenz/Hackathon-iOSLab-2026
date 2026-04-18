import Foundation

// MARK: - Microaction Enums

enum MicroactionStatus: String, Codable {
    case pending, completed, skipped, snoozed
}

enum ScheduleHint: String, Codable {
    case morning, midday, afternoon, evening
    case beforeBed = "before_bed"
}

// MARK: - MicroactionWithStatus

struct MicroactionWithStatus: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let justification: String
    let category: String
    let difficulty: String
    let estimatedMinutes: Int
    let scheduleHint: ScheduleHint?
    let status: MicroactionStatus
    let completedAt: String?
    let skippedAt: String?
}

// MARK: - Daily Brief

struct DailyBriefLastEmotion: Codable {
    let id: String
    let checkedAt: String
    let checkinType: String
    let emotionFamily: String
    let emotionLabel: String
    let intensity: Int
}

struct DailyBriefStreak: Codable {
    let current: Int
    let longest: Int
    let actionCompletionCurrent: Int
    let actionCompletionLongest: Int
}

struct DailyBrief: Codable {
    let date: String
    let primaryMicroaction: MicroactionWithStatus?
    let supportingActions: [MicroactionWithStatus]
    let motivationMessage: String
    let focusArea: String
    let whyThisToday: String
    let recoveryMode: Bool
    let lastEmotion: DailyBriefLastEmotion?
    let streak: DailyBriefStreak
    let adaptationNote: String?
    let recoveryNote: String?
}

// MARK: - Emotions

enum EmotionFamily: String, Codable {
    case joy, sadness, anger, fear, disgust, surprise, trust, anticipation
}

enum CheckinType: String, Codable {
    case morning, midday, evening, manual
    case postAction = "post_action"
}

struct EmotionCheckinRequest: Encodable {
    let checkinType: CheckinType
    let emotionFamily: EmotionFamily
    let emotionLabel: String
    let intensity: Int
    let triggerContext: String?
    let microactionId: String?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case checkinType = "checkin_type"
        case emotionFamily = "emotion_family"
        case emotionLabel = "emotion_label"
        case intensity
        case triggerContext = "trigger_context"
        case microactionId = "microaction_id"
        case notes
    }
}

struct SuggestedAdjustment: Codable {
    let message: String
    let toneShift: String
}

struct EmotionCheckinResponse: Codable {
    let id: String
    let checkedAt: String
    let compassionateResponse: String
    let suggestedAdjustment: SuggestedAdjustment?
}

struct EmotionHistoryItem: Codable, Identifiable {
    let id: String
    let checkedAt: String
    let checkinType: String
    let emotionFamily: String
    let emotionLabel: String
    let valence: Double
    let arousal: Double
    let intensity: Int
    let triggerContext: String?
    let microactionId: String?
    let notes: String?
}

struct EmotionHistoryResponse: Codable {
    let items: [EmotionHistoryItem]
    let limit: Int
    let offset: Int
}

// MARK: - User

struct UserMe: Codable {
    let id: String
    let clerkUserId: String?
    let appleSub: String?
    let googleSub: String?
    let email: String?
    let name: String?
    let onboardingCompleted: Bool
    let timezone: String
    let preferredTone: String?
    let goals: [String]
    let createdAt: String?
    let updatedAt: String?
}

struct PatchUserBody: Encodable {
    let name: String?
    let email: String?
    let timezone: String?
    let preferredTone: String?
    let goals: [String]?
    let onboardingCompleted: Bool?

    enum CodingKeys: String, CodingKey {
        case name, email, timezone, goals
        case preferredTone = "preferred_tone"
        case onboardingCompleted = "onboarding_completed"
    }
}

// MARK: - Streak

struct StreakDetail: Codable {
    let current: Int
    let longest: Int
}

struct StreakBundle: Codable {
    let dailyUse: StreakDetail
    let actionCompletion: StreakDetail
}

// MARK: - Actions Today

struct GetActionsTodayResponse: Codable {
    let date: String?
    let sessionId: String?
    let microactions: [MicroactionWithStatus]
    let motivationMessage: String
    let focusArea: String
}

// MARK: - Health Summary

struct HealthSummaryRequest: Encodable {
    let startDate: String
    let endDate: String

    enum CodingKeys: String, CodingKey {
        case startDate = "start_date"
        case endDate = "end_date"
    }
}

struct HealthSummaryResponse: Codable {
    let summary: String
    let insights: [String]?
}
