import Foundation
import Combine

@MainActor
final class ProgressScreenViewModel: ObservableObject {
    // MARK: - Published State

    @Published var title = "Tu Progreso"
    @Published var subtitle = "Últimos 7 días"
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Semana data
    @Published var weeklyScore = 0
    @Published var weeklyDelta = ""
    @Published var totalSteps = "—"
    @Published var averageSleep = "—"
    @Published var averageMoodScore = "—"
    @Published var averageStressScore = "—"
    @Published var streakCurrent = 0
    @Published var streakLongest = 0
    @Published var coachInsight = ""
    @Published var coachFocusArea = ""
    @Published var moodChartData: [(label: String, value: Double, level: Int)] = []
    @Published var achievements: [String] = []
    @Published var healthSummary: HealthSummaryResponse?
    @Published var hasInsufficientData = false

    // Mapa data
    @Published var compassionateResponse: String?

    // Emotion history
    @Published var emotionHistory: [EmotionHistoryItem] = []

    // Diario data
    @Published var journalSessions: [ChatSessionSummary] = []
    @Published var isLoadingJournal = false
    @Published var journalErrorMessage: String?

    // MARK: - Dependencies

    private let dailyBriefService: DailyBriefServiceProtocol
    private let emotionsService: EmotionsServiceProtocol
    private let userService: UserServiceProtocol
    private let healthDataProvider: HealthDataProviding
    private let coachService: CoachServiceProtocol

    init() {
        if Self.isRunningInPreview {
            self.dailyBriefService = MockDailyBriefService()
            self.emotionsService = MockEmotionsService()
            self.userService = MockUserService()
            self.healthDataProvider = MockHealthDataProvider()
            self.coachService = MockCoachService()
        } else {
            let client = APIClient()
            self.dailyBriefService = DailyBriefAPIService(apiClient: client)
            self.emotionsService = EmotionsAPIService(apiClient: client)
            self.userService = UserAPIService(apiClient: client)
            self.healthDataProvider = HealthKitHealthDataProvider(healthKitManager: HealthKitManager())
            self.coachService = CoachAPIService(apiClient: client)
        }
    }

    init(
        dailyBriefService: DailyBriefServiceProtocol,
        emotionsService: EmotionsServiceProtocol,
        userService: UserServiceProtocol,
        healthDataProvider: HealthDataProviding,
        coachService: CoachServiceProtocol
    ) {
        self.dailyBriefService = dailyBriefService
        self.emotionsService = emotionsService
        self.userService = userService
        self.healthDataProvider = healthDataProvider
        self.coachService = coachService
    }

    // MARK: - Load Semana

    func loadSemanaData() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        async let briefTask = loadDailyBrief()
        async let emotionsTask = loadEmotionHistory()
        async let streakTask = loadStreak()
        async let healthTask = loadHealthSnapshot()

        await briefTask
        await emotionsTask
        await streakTask
        await healthTask

        deriveMoodChart()
        deriveScoreCards()
        deriveAchievements()
        await loadHealthSummary()

        if coachInsight.isEmpty,
           moodChartData.isEmpty,
           healthSummary == nil,
           emotionHistory.isEmpty {
            errorMessage = "No pudimos cargar el resumen semanal todavía."
        }
    }

    private func loadDailyBrief() async {
        do {
            let brief = try await dailyBriefService.getDailyBrief()
            coachInsight = brief.whyThisToday
            coachFocusArea = brief.focusArea
            streakCurrent = brief.streak.current
            streakLongest = brief.streak.longest
        } catch {
            Self.debugLog("daily-brief error: \(error.localizedDescription)")
        }
    }

    private func loadEmotionHistory() async {
        do {
            let response = try await emotionsService.getHistory(limit: 30, offset: 0)
            emotionHistory = response.items
        } catch {
            Self.debugLog("emotion history error: \(error.localizedDescription)")
        }
    }

    private func loadStreak() async {
        do {
            let bundle = try await userService.getStreak()
            streakCurrent = bundle.actionCompletion.current
            streakLongest = bundle.actionCompletion.longest
        } catch {
            Self.debugLog("streak error: \(error.localizedDescription)")
        }
    }

    private func deriveMoodChart() {
        let calendar = Calendar.current
        let dayLabels = ["L", "M", "X", "J", "V", "S", "D"]
        let today = calendar.startOfDay(for: Date())

        var chartPoints: [(label: String, value: Double, level: Int)] = []
        for dayOffset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let weekday = calendar.component(.weekday, from: date)
            let label = dayLabels[(weekday + 5) % 7] // Monday=0

            // Average intensity of emotions for this day
            let dayEmotions = emotionHistory.filter { item in
                guard let itemDate = ISO8601DateFormatter().date(from: item.checkedAt) else { return false }
                return calendar.isDate(itemDate, inSameDayAs: date)
            }

            let avgIntensity: Double
            if dayEmotions.isEmpty {
                avgIntensity = 0.5
            } else {
                avgIntensity = Double(dayEmotions.map(\.intensity).reduce(0, +)) / Double(dayEmotions.count) / 10.0
            }

            let level: Int
            if avgIntensity < 0.4 { level = 0 }       // bienestar
            else if avgIntensity < 0.65 { level = 1 }  // medio
            else { level = 2 }                          // alto

            chartPoints.append((label: label, value: avgIntensity, level: level))
        }
        moodChartData = chartPoints
    }

    private func loadHealthSnapshot() async {
        do {
            let snapshot = try await healthDataProvider.fetchCurrentSnapshot()
            totalSteps = "\(snapshot.stepsToday)"
            averageSleep = String(format: "%.1fh", snapshot.sleepHoursLastNight)
        } catch {
            Self.debugLog("health snapshot error: \(error.localizedDescription)")
        }
    }

    private func deriveScoreCards() {
        guard !emotionHistory.isEmpty else {
            averageMoodScore = "—"
            averageStressScore = "—"
            weeklyScore = 0
            weeklyDelta = ""
            return
        }

        let avgValence = emotionHistory.map(\.valence).reduce(0, +) / Double(emotionHistory.count)
        let moodScore = max(0, min(10, ((avgValence + 1.0) / 2.0) * 10.0))
        averageMoodScore = String(format: "%.1f", moodScore)

        let avgIntensity = Double(emotionHistory.map(\.intensity).reduce(0, +)) / Double(emotionHistory.count)
        averageStressScore = String(format: "%.1f", avgIntensity)
        weeklyScore = Int(moodScore.rounded())

        guard emotionHistory.count >= 2 else {
            weeklyDelta = ""
            return
        }

        let recentWindow = Array(emotionHistory.prefix(3))
        let previousWindow = Array(emotionHistory.dropFirst(3).prefix(3))
        guard !previousWindow.isEmpty else {
            weeklyDelta = ""
            return
        }

        let recentValence = recentWindow.map(\.valence).reduce(0, +) / Double(recentWindow.count)
        let previousValence = previousWindow.map(\.valence).reduce(0, +) / Double(previousWindow.count)
        let delta = ((recentValence - previousValence) / 2.0) * 10.0

        if abs(delta) < 0.2 {
            weeklyDelta = "estable"
        } else {
            let prefix = delta > 0 ? "+" : ""
            weeklyDelta = "\(prefix)\(String(format: "%.1f", delta))"
        }
    }

    private func deriveAchievements() {
        var list: [String] = []
        if streakCurrent >= 7 { list.append("Racha de \(streakCurrent) días") }
        if streakCurrent >= 1 { list.append("Constancia diaria") }
        if !emotionHistory.isEmpty { list.append("Registro emocional activo") }
        achievements = list
    }

    // MARK: - Submit Emotion (Mapa)

    func submitEmotion(family: EmotionFamily, label: String, intensity: Int) async {
        let request = EmotionCheckinRequest(
            checkinType: EmotionMapping.currentCheckinType(),
            emotionFamily: family,
            emotionLabel: label,
            intensity: intensity,
            triggerContext: nil,
            microactionId: nil,
            notes: nil
        )

        do {
            let response = try await emotionsService.submitCheckin(request)
            compassionateResponse = response.compassionateResponse
            Self.debugLog("POST /emotions/checkin OK from Mapa")
        } catch {
            compassionateResponse = "Gracias por compartir cómo te sientes."
            Self.debugLog("POST /emotions/checkin failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Diario

    func loadJournalData() async {
        isLoadingJournal = true
        journalErrorMessage = nil
        defer { isLoadingJournal = false }

        do {
            let sessions = try await coachService.listChatSessions(sessionKind: .journal)
            let sorted = sessions.sorted { lhs, rhs in
                (lhs.journalDate ?? lhs.lastMessageAt ?? "") > (rhs.journalDate ?? rhs.lastMessageAt ?? "")
            }
            let today = sorted.filter(\.isToday)
            let previous = sorted.filter { !$0.isToday }.prefix(3)
            journalSessions = today + previous
        } catch {
            journalSessions = []
            journalErrorMessage = "No pudimos cargar tu diario todavía."
        }
    }

    var todayJournalSession: ChatSessionSummary? {
        journalSessions.first(where: \.isToday)
    }

    var previousJournalSessions: [ChatSessionSummary] {
        journalSessions.filter { !$0.isToday }
    }

    // MARK: - Health Summary (Semana)

    func loadHealthSummary() async {
        let calendar = Calendar.current
        let formatter = ISO8601DateFormatter()
        let end = Date()
        guard let start = calendar.date(byAdding: .day, value: -7, to: end) else { return }

        // Check if we have enough data (~4 days)
        let daysWithData = Set(emotionHistory.compactMap { item -> String? in
            guard let date = formatter.date(from: item.checkedAt) else { return nil }
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            return df.string(from: date)
        }).count

        if daysWithData < 4 {
            hasInsufficientData = true
            return
        }

        hasInsufficientData = false
        let request = HealthSummaryRequest(
            startDate: formatter.string(from: start),
            endDate: formatter.string(from: end)
        )

        do {
            healthSummary = try await dailyBriefService.postHealthSummary(request)
            Self.debugLog("POST /health-summary OK")
        } catch {
            errorMessage = "No pudimos generar el resumen semanal."
            Self.debugLog("POST /health-summary failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers

    private static var isRunningInPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    private static func debugLog(_ message: String) {
        #if DEBUG
        print("ProgressVM -> \(message)")
        #endif
    }
}
