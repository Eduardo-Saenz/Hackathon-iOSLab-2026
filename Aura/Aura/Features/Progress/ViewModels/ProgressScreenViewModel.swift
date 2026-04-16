import Foundation
import Combine

@MainActor
final class ProgressScreenViewModel: ObservableObject {
    @Published var title = "Tu Progreso"
    @Published var subtitle = "Últimos 7 días"
    @Published var weeklyScore = 782
    @Published var weeklyDelta = "+12% vs semana pasada"
    @Published var totalSteps = "39,241"
    @Published var averageSleep = "7.0h"
    @Published var stepTrend: [Double] = [0.62, 0.66, 0.54, 0.68, 0.61, 0.73, 0.55]
    @Published var sleepTrend: [Double] = [0.58, 0.59, 0.61, 0.57, 0.62, 0.62, 0.56]
    @Published var achievements: [String] = ["🥇 Primera semana", "💧 Hidratación total", "🔥 Racha de 7 días", "🧘 Mindfulness Pro"]

    init() {}
}
