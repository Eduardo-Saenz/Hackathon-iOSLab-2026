import SwiftUI

@MainActor
struct ProgressViewScreen: View {
    @StateObject private var viewModel: ProgressScreenViewModel

    init() {
        _viewModel = StateObject(wrappedValue: ProgressScreenViewModel())
    }

    init(viewModel: ProgressScreenViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AuraSpacing.large) {
                VStack(alignment: .leading, spacing: AuraSpacing.xSmall) {
                    Text(viewModel.title)
                        .font(AuraTypography.title2)
                        .foregroundStyle(AuraColors.textPrimary)
                    Text(viewModel.subtitle)
                        .font(AuraTypography.caption)
                        .foregroundStyle(AuraColors.textSecondary)
                }

                VStack(alignment: .leading, spacing: AuraSpacing.small) {
                    Text("PUNTUACIÓN SEMANAL")
                        .font(AuraTypography.caption)
                        .foregroundStyle(AuraColors.textSecondary)
                    Text("\(viewModel.weeklyScore)")
                        .font(AuraTypography.title)
                        .foregroundStyle(AuraColors.textPrimary)
                    Text(viewModel.weeklyDelta)
                        .font(AuraTypography.footnote)
                        .foregroundStyle(AuraColors.textPrimary.opacity(0.8))
                }
                .padding(AuraSpacing.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(red: 0.80, green: 0.94, blue: 0.97))
                .clipShape(RoundedRectangle(cornerRadius: AuraCorners.large))

                trendCard(
                    title: "PASOS DIARIOS",
                    value: "\(viewModel.totalSteps) esta semana",
                    icon: "👟",
                    lineColor: AuraColors.primary,
                    points: viewModel.stepTrend
                )

                trendCard(
                    title: "CALIDAD DE SUEÑO",
                    value: "\(viewModel.averageSleep) promedio",
                    icon: "🌙",
                    lineColor: AuraColors.secondary,
                    points: viewModel.sleepTrend
                )

                VStack(alignment: .leading, spacing: AuraSpacing.medium) {
                    Text("TUS LOGROS")
                        .font(AuraTypography.caption)
                        .foregroundStyle(AuraColors.textSecondary)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AuraSpacing.small), count: 4), spacing: AuraSpacing.small) {
                        ForEach(viewModel.achievements, id: \.self) { badge in
                            Text(badge)
                                .font(AuraTypography.caption)
                                .foregroundStyle(AuraColors.textPrimary)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, minHeight: 72)
                                .padding(.horizontal, AuraSpacing.small)
                                .background(AuraColors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: AuraCorners.medium))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AuraCorners.medium)
                                        .stroke(AuraColors.cardStroke, lineWidth: 1)
                                )
                        }
                    }
                }
            }
            .padding(AuraSpacing.large)
        }
        .background(AuraColors.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private func trendCard(title: String, value: String, icon: String, lineColor: Color, points: [Double]) -> some View {
        VStack(alignment: .leading, spacing: AuraSpacing.smedium) {
            HStack {
                VStack(alignment: .leading, spacing: AuraSpacing.xSmall) {
                    Text(title)
                        .font(AuraTypography.caption)
                        .foregroundStyle(AuraColors.textSecondary)
                    Text(value)
                        .font(AuraTypography.headline)
                        .foregroundStyle(AuraColors.textPrimary)
                }
                Spacer()
                Text(icon)
                    .font(.system(size: 22))
                    .frame(width: 42, height: 42)
                    .background(AuraColors.surfaceMuted)
                    .clipShape(Circle())
            }

            SparklineView(points: points, color: lineColor)
                .frame(height: 56)
        }
        .padding(AuraSpacing.medium)
        .background(AuraColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AuraCorners.large))
        .overlay(
            RoundedRectangle(cornerRadius: AuraCorners.large)
                .stroke(AuraColors.cardStroke.opacity(0.8), lineWidth: 1)
        )
    }
}

private struct SparklineView: View {
    let points: [Double]
    let color: Color

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let values = points.isEmpty ? [0.0] : points
            let maxValue = values.max() ?? 1
            let minValue = values.min() ?? 0
            let range = max(maxValue - minValue, 0.0001)

            Path { path in
                for (index, value) in values.enumerated() {
                    let x = CGFloat(index) * (width / CGFloat(max(values.count - 1, 1)))
                    let normalized = (value - minValue) / range
                    let y = height - (CGFloat(normalized) * (height - 4)) - 2

                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
        }
    }
}

#Preview {
    NavigationStack {
        ProgressViewScreen()
    }
}
