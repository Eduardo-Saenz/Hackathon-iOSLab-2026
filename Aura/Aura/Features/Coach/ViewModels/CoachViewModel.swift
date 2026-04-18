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
    @Published var messages: [CoachMessage] = [
        CoachMessage(
            id: UUID(),
            text: "Hola, soy tu Coach AI. Estoy listo para ayudarte con acciones concretas para hoy.",
            isFromUser: false,
            time: "09:01"
        )
    ]
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

    private let coachService: CoachServiceProtocol
    private let healthDataProvider: HealthDataProviding
    private let appPreferences: AppPreferences
    private let maxHistoryToSend = 12
    private let isRuntimeService: Bool

    private var lastFailedUserMessage: String?

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
    }

    init(
        coachService: CoachServiceProtocol,
        healthDataProvider: HealthDataProviding,
        appPreferences: AppPreferences,
        isRuntimeService: Bool
    ) {
        self.coachService = coachService
        self.healthDataProvider = healthDataProvider
        self.appPreferences = appPreferences
        self.isRuntimeService = isRuntimeService
    }

    func sendDraft() {
        let trimmed = draftMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isLoading else { return }

        draftMessage = ""
        Task {
            await sendMessage(trimmed)
        }
    }

    func retryLastMessage() {
        guard let lastFailedUserMessage, !isLoading else { return }
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
            let response = try await coachService.sendChat(messages: payloadMessages, healthContext: healthContext)
            appendMessage(response.message, isFromUser: false)
            lastResponseGrounded = response.grounded
            lastResponseDisclaimer = response.disclaimer
            usedBackendInLastResponse = isRuntimeService
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
        let allowedGoals = Set(["sleep", "steps", "energy", "weight"])
        let persisted = appPreferences.selectedGoalIDs.filter { allowedGoals.contains($0) }

        if !persisted.isEmpty {
            return Array(persisted.prefix(4))
        }

        return WellnessGoal.predefined
            .map(\.id)
            .filter { allowedGoals.contains($0) }
            .prefix(3)
            .map { $0 }
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
}
