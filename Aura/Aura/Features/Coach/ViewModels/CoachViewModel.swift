import Foundation
import Combine

struct CoachMessage: Identifiable {
    let id: UUID
    let text: String
    let isFromUser: Bool
    let time: String
}

@MainActor
final class CoachViewModel: ObservableObject {
    @Published var messages: [CoachMessage] = []
    @Published var quickReplies: [String] = [
        "Tengo poca energía hoy",
        "¿Qué hago para dormir mejor?"
    ]
    @Published var draftMessage = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastResponseGrounded: Bool?
    @Published var lastResponseDisclaimer: String?
    @Published var usedBackendInLastResponse = false
    @Published var sessionId: String?
    @Published var isReadOnly = false
    @Published var readOnlyNotice: String?
    @Published var journalDate: String?

    private let coachService: CoachServiceProtocol
    private let healthDataProvider: HealthDataProviding
    private let appPreferences: AppPreferences
    private let maxHistoryToSend = 12
    private let isRuntimeService: Bool
    private let preferredSessionKind: ChatSessionKind

    private var lastFailedUserMessage: String?
    private var hasLoadedInitialSession = false

    init() {
        if Self.isRunningInPreview {
            self.coachService = MockCoachService()
            self.healthDataProvider = MockHealthDataProvider()
            self.appPreferences = .shared
            self.isRuntimeService = false
        } else {
            let manager = HealthKitManager()
            self.coachService = CoachAPIService(apiClient: APIClient())
            self.healthDataProvider = HealthKitHealthDataProvider(healthKitManager: manager)
            self.appPreferences = .shared
            self.isRuntimeService = true
        }
        self.preferredSessionKind = .general
        seedWelcomeMessageIfNeeded()
    }

    init(
        initialSessionId: String? = nil,
        sessionKind: ChatSessionKind,
        isReadOnly: Bool,
        coachService: CoachServiceProtocol,
        healthDataProvider: HealthDataProviding,
        appPreferences: AppPreferences,
        isRuntimeService: Bool
    ) {
        self.coachService = coachService
        self.healthDataProvider = healthDataProvider
        self.appPreferences = appPreferences
        self.isRuntimeService = isRuntimeService
        self.preferredSessionKind = sessionKind
        self.isReadOnly = isReadOnly
        if sessionKind == .journal {
            self.sessionId = initialSessionId ?? appPreferences.chatSessionId
        } else {
            self.sessionId = initialSessionId
        }
        if isReadOnly {
            self.readOnlyNotice = "This journal entry is from a previous day. Continue writing in today's journal."
        }
        seedWelcomeMessageIfNeeded()
    }

    convenience init(
        initialSessionId: String? = nil,
        sessionKind: ChatSessionKind = .general,
        isReadOnly: Bool = false
    ) {
        if Self.isRunningInPreview {
            self.init(
                initialSessionId: initialSessionId,
                sessionKind: sessionKind,
                isReadOnly: isReadOnly,
                coachService: MockCoachService(),
                healthDataProvider: MockHealthDataProvider(),
                appPreferences: .shared,
                isRuntimeService: false
            )
        } else {
            let manager = HealthKitManager()
            self.init(
                initialSessionId: initialSessionId,
                sessionKind: sessionKind,
                isReadOnly: isReadOnly,
                coachService: CoachAPIService(apiClient: APIClient()),
                healthDataProvider: HealthKitHealthDataProvider(healthKitManager: manager),
                appPreferences: .shared,
                isRuntimeService: true
            )
        }
    }

    func loadInitialSessionIfNeeded() async {
        guard !hasLoadedInitialSession else { return }
        hasLoadedInitialSession = true

        guard let sessionId else {
            seedWelcomeMessageIfNeeded()
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await coachService.getChatSessionMessages(sessionId: sessionId)
            applySessionMetadata(response.session)
            let restored = response.messages.map { message in
                CoachMessage(
                    id: UUID(uuidString: message.id) ?? UUID(),
                    text: message.content,
                    isFromUser: message.role == .user,
                    time: Self.timeString(from: message.createdAt)
                )
            }
            messages = restored
            seedWelcomeMessageIfNeeded()
        } catch {
            self.errorMessage = error.localizedDescription
            if preferredSessionKind == .journal {
                self.sessionId = nil
                appPreferences.chatSessionId = nil
            }
            seedWelcomeMessageIfNeeded()
        }
    }

    func sendDraft() {
        let trimmed = draftMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isLoading, !isReadOnly else { return }

        draftMessage = ""
        Task {
            await sendMessage(trimmed)
        }
    }

    func retryLastMessage() {
        guard let lastFailedUserMessage, !isLoading, !isReadOnly else { return }
        Task {
            await sendMessage(lastFailedUserMessage)
        }
    }

    private func sendMessage(_ text: String) async {
        errorMessage = nil
        lastFailedUserMessage = nil

        appendMessage(text, isFromUser: true)
        isLoading = true
        defer { isLoading = false }

        let payloadMessages = mapRecentMessagesForBackend()
        let healthContext = await buildHealthContext()

        do {
            let response = try await coachService.sendChat(
                messages: payloadMessages,
                healthContext: healthContext,
                sessionId: sessionId,
                sessionKind: preferredSessionKind
            )
            appendMessage(response.message, isFromUser: false)
            lastResponseGrounded = response.grounded
            lastResponseDisclaimer = response.disclaimer
            usedBackendInLastResponse = isRuntimeService
            if let newSessionId = response.sessionId {
                sessionId = newSessionId
                if preferredSessionKind == .journal {
                    appPreferences.chatSessionId = newSessionId
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            lastFailedUserMessage = text
            usedBackendInLastResponse = false
        }
    }

    private func appendMessage(_ text: String, isFromUser: Bool) {
        messages.append(
            CoachMessage(
                id: UUID(),
                text: text,
                isFromUser: isFromUser,
                time: Self.timeFormatter.string(from: Date())
            )
        )
    }

    private func mapRecentMessagesForBackend() -> [ChatMessagePayload] {
        let recent = messages.suffix(maxHistoryToSend)
        return recent.map { message in
            ChatMessagePayload(
                role: message.isFromUser ? .user : .assistant,
                content: message.text
            )
        }
    }

    private func buildHealthContext() async -> ChatHealthContextPayload? {
        do {
            let snapshot = try await healthDataProvider.fetchCurrentSnapshot()
            let healthPayload = HealthKitMapper.mapToPayload(snapshot)
            let goals = resolvedGoals()
            return ChatHealthContextPayload(healthData: healthPayload, userGoals: goals)
        } catch {
            return nil
        }
    }

    private func resolvedGoals() -> [String] {
        let persisted = appPreferences.selectedGoalIDs
        if !persisted.isEmpty {
            return GoalMapping.mapGoals(Array(persisted.prefix(4)))
        }
        return GoalMapping.mapGoals(WellnessGoal.predefined.prefix(3).map(\.id))
    }

    private func applySessionMetadata(_ metadata: ChatSessionMetadata) {
        sessionId = metadata.id
        journalDate = metadata.journalDate
        isReadOnly = !metadata.isWritable
        if preferredSessionKind == .journal {
            appPreferences.chatSessionId = metadata.isWritable ? metadata.id : nil
        }
        if !metadata.isWritable {
            readOnlyNotice = "This journal entry is from a previous day. Continue writing in today's journal."
        } else {
            readOnlyNotice = nil
        }
    }

    private func seedWelcomeMessageIfNeeded() {
        guard messages.isEmpty else { return }
        messages = [
            CoachMessage(
                id: UUID(),
                text: "Hola, soy tu Coach AI. Estoy listo para ayudarte con acciones concretas para hoy.",
                isFromUser: false,
                time: Self.timeFormatter.string(from: Date())
            )
        ]
    }
}

private extension CoachViewModel {
    static var isRunningInPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()

    static func timeString(from isoDate: String?) -> String {
        guard
            let isoDate,
            let date = ISO8601DateFormatter().date(from: isoDate)
        else {
            return timeFormatter.string(from: Date())
        }
        return timeFormatter.string(from: date)
    }
}
