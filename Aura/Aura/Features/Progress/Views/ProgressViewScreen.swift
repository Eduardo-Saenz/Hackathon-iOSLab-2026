import SwiftUI

struct ChartDataPoint {
    let day: String
    let fill: Double
    let dot: Color
}

struct EmotionCategory {
    let name: String
    let inner: String
    let middle: String
    let outer: String
    let color: Color
}

@MainActor
struct ProgressViewScreen: View {
    @StateObject private var viewModel: ProgressScreenViewModel
    @State private var selectedTab = "Diario" // Set to Diario by default to show off the new feature
    @State private var animateBars = false

    private let bienestarColor = Color(hex: "#5FD1B8")
    private let medioColor = Color(hex: "#FFBE5C")
    private let altoColor = Color(hex: "#FF7B7B")

    private var weeklyData: [ChartDataPoint] {
        [
            ChartDataPoint(day: "L", fill: 0.5, dot: medioColor),
            ChartDataPoint(day: "M", fill: 0.4, dot: medioColor),
            ChartDataPoint(day: "X", fill: 0.7, dot: bienestarColor),
            ChartDataPoint(day: "J", fill: 0.35, dot: altoColor),
            ChartDataPoint(day: "V", fill: 0.65, dot: medioColor),
            ChartDataPoint(day: "S", fill: 0.85, dot: bienestarColor),
            ChartDataPoint(day: "D", fill: 0.4, dot: altoColor)
        ]
    }

    private let wheelCategories: [EmotionCategory] = [
        EmotionCategory(name: "Alegría", inner: "Éxtasis", middle: "Alegría", outer: "Serenidad", color: Color(hex: "#FFCF70")), // Yellow/Gold
        EmotionCategory(name: "Confianza", inner: "Admiración", middle: "Confianza", outer: "Aceptación", color: Color(hex: "#A1E3D6")), // Mint
        EmotionCategory(name: "Miedo", inner: "Terror", middle: "Miedo", outer: "Aprensión", color: Color(hex: "#82E0AA")), // Green
        EmotionCategory(name: "Sorpresa", inner: "Asombro", middle: "Sorpresa", outer: "Distracción", color: Color(hex: "#85C1E9")), // Light Blue
        EmotionCategory(name: "Tristeza", inner: "Pena", middle: "Tristeza", outer: "Pensatividad", color: Color(hex: "#C4B6DB")), // Lavender
        EmotionCategory(name: "Disgusto", inner: "Repulsión", middle: "Disgusto", outer: "Aburrimiento", color: Color(hex: "#D2B4DE")), // Purple
        EmotionCategory(name: "Enojo", inner: "Rabia", middle: "Enojo", outer: "Molestia", color: Color(hex: "#F1948A")), // Red/Pink
        EmotionCategory(name: "Anticip", inner: "Vigilancia", middle: "Anticipación", outer: "Interés", color: Color(hex: "#F5B041")) // Orange
    ]

    init() {
        _viewModel = StateObject(wrappedValue: ProgressScreenViewModel())
    }

    init(viewModel: ProgressScreenViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AuraSpacing.xLarge) {
                headerSection
                segmentedControlSection
                
                if selectedTab == "Semana" {
                    semanaSection
                } else if selectedTab == "Mapa" {
                    mapaSection
                } else {
                    diarioSection
                }
            }
            .padding(AuraSpacing.large)
            .padding(.bottom, 60)
        }
        .background(AuraColors.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            if selectedTab == "Semana" {
                animateBars = true
            }
        }
        .onChange(of: selectedTab) { newValue in
            if newValue == "Semana" {
                withAnimation { animateBars = true }
            } else {
                animateBars = false
            }
        }
    }

    @ViewBuilder
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Tu Bienestar Mental")
                .font(AuraTypography.title2)
                .foregroundStyle(AuraColors.textPrimary)
            Text("Reflexiones y patrones de la semana")
                .font(AuraTypography.footnote)
                .foregroundStyle(AuraColors.textSecondary)
        }
    }

    @ViewBuilder
    private var segmentedControlSection: some View {
        HStack(spacing: 0) {
            ForEach(["Semana", "Mapa", "Diario"], id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                } label: {
                    Text(tab)
                        .font(AuraTypography.footnote)
                        .foregroundStyle(selectedTab == tab ? AuraColors.textPrimary : AuraColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedTab == tab ? AuraColors.surface : Color.clear)
                        .clipShape(Capsule())
                        .shadow(color: selectedTab == tab ? Color.black.opacity(0.05) : Color.clear, radius: 2, y: 1)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(AuraColors.surfaceMuted)
        .clipShape(Capsule())
    }

    @ViewBuilder
    private var semanaSection: some View {
        VStack(spacing: AuraSpacing.xLarge) {
            aiCoachSection
            moodChartSection
            summaryCardsSection
        }
    }
    
    @ViewBuilder
    private var mapaSection: some View {
        VStack(alignment: .leading, spacing: AuraSpacing.xLarge) {
            VStack(alignment: .leading, spacing: AuraSpacing.small) {
                Text("RUEDA DE EMOCIONES")
                    .font(AuraTypography.mini)
                    .foregroundStyle(AuraColors.textSecondary)
                    .tracking(1)
                
                Text("¿Qué estás sintiendo hoy?")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(AuraColors.textPrimary)
            }
            
            emotionWheelCard
        }
        .padding(AuraSpacing.large)
        .background(AuraColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AuraCorners.large))
        .shadow(color: Color.black.opacity(0.02), radius: 8, y: 4)
    }

    @ViewBuilder
    private var emotionWheelCard: some View {
        VStack(spacing: AuraSpacing.xLarge) {
            
            // Rueda interactiva
            ZStack {
                ForEach(Array(wheelCategories.enumerated()), id: \.offset) { index, category in
                    let angleDegree = Double(index) * 45.0 - 90.0
                    let startAngle = Angle(degrees: angleDegree - 22.5)
                    let endAngle = Angle(degrees: angleDegree + 22.5)
                    
                    // Outer Ring
                    EmotionSlice(startAngle: startAngle, endAngle: endAngle, innerRadius: 100, outerRadius: 150, color: category.color.opacity(0.2), text: category.outer, textColor: AuraColors.textSecondary)
                    
                    // Middle Ring
                    EmotionSlice(startAngle: startAngle, endAngle: endAngle, innerRadius: 50, outerRadius: 100, color: category.color.opacity(0.6), text: category.middle, textColor: AuraColors.textPrimary)
                    
                    // Inner Ring
                    EmotionSlice(startAngle: startAngle, endAngle: endAngle, innerRadius: 20, outerRadius: 50, color: category.color, text: category.inner, textColor: .white)
                }
                
                // Centro YO
                Circle()
                    .fill(AuraColors.surface)
                    .frame(width: 40, height: 40)
                    .shadow(color: Color.black.opacity(0.1), radius: 4)
                    .overlay(
                        Text("YO")
                            .font(AuraTypography.mini)
                            .foregroundStyle(AuraColors.textSecondary)
                    )
            }
            .frame(width: 300, height: 300)
            .padding(.vertical, AuraSpacing.medium)
            
            Text("Toca un segmento para identificar tu emoción")
                .font(AuraTypography.footnote)
                .foregroundStyle(AuraColors.textSecondary)
                .padding(.top, AuraSpacing.small)
            
            // Grid inferior
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AuraSpacing.small), count: 4), spacing: AuraSpacing.small) {
                ForEach(wheelCategories, id: \.name) { cat in
                    Button {
                        // Acción de selección
                    } label: {
                        VStack(spacing: 8) {
                            Circle()
                                .fill(cat.color)
                                .frame(width: 14, height: 14)
                            Text(cat.name)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(AuraColors.textPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 4)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: AuraCorners.medium))
                        .shadow(color: Color.black.opacity(0.03), radius: 4, y: 2)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var aiCoachSection: some View {
        VStack(alignment: .leading, spacing: AuraSpacing.medium) {
            HStack(spacing: AuraSpacing.xSmall) {
                Image(systemName: "note.text")
                    .foregroundStyle(AuraColors.primary)
                    .font(.system(size: 14))
                Text("INFORME DEL CONSEJERO")
                    .font(AuraTypography.mini)
                    .foregroundStyle(AuraColors.primary)
                    .tracking(1)
            }
            
            Text("Esta semana tu mente trabajó duro")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(AuraColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            
            Text("Notamos un patrón: los días con menos de 6.5h de sueño correlacionan con niveles de estrés más altos y menor bienestar emocional. Priorizar el sueño esta semana puede marcar una diferencia significativa.")
                .font(AuraTypography.body)
                .foregroundStyle(AuraColors.textSecondary)
                .lineSpacing(4)
            
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "target")
                    .foregroundStyle(altoColor)
                    .font(.system(size: 16, weight: .bold))
                    .padding(.top, 2)
                Text("Enfoque: Sueño como base del bienestar mental")
                    .font(AuraTypography.footnote)
                    .foregroundStyle(AuraColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(AuraSpacing.medium)
            .background(Color.white.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: AuraCorners.medium))
        }
        .padding(AuraSpacing.large)
        .background(
            ZStack {
                Color(hex: "#EFF8F9")
                
                Circle()
                    .fill(AuraColors.blueSoft.opacity(0.8))
                    .frame(width: 250, height: 250)
                    .blur(radius: 50)
                    .offset(x: 100, y: 80)
            }
            .clipShape(RoundedRectangle(cornerRadius: AuraCorners.large))
        )
    }

    @ViewBuilder
    private var moodChartSection: some View {
        VStack(alignment: .leading, spacing: AuraSpacing.large) {
            VStack(alignment: .leading, spacing: AuraSpacing.small) {
                Text("ESTADO DE ÁNIMO")
                    .font(AuraTypography.mini)
                    .foregroundStyle(AuraColors.textSecondary)
                    .tracking(1)
                
                HStack(spacing: AuraSpacing.medium) {
                    legendItem(color: bienestarColor, text: "Bienestar")
                    legendItem(color: altoColor, text: "Estrés alto")
                    legendItem(color: medioColor, text: "Estrés medio")
                }
            }
            
            HStack(spacing: 0) {
                ForEach(Array(weeklyData.enumerated()), id: \.offset) { offset, item in
                    Spacer()
                    VStack(spacing: AuraSpacing.small) {
                        ZStack(alignment: .bottom) {
                            Capsule()
                                .fill(AuraColors.surfaceMuted.opacity(0.8))
                                .frame(width: 24, height: 100)
                            Capsule()
                                .fill(item.dot)
                                .frame(width: 24, height: animateBars ? 100 * item.fill : 0)
                                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(Double(offset) * 0.05), value: animateBars)
                        }
                        Circle()
                            .fill(item.dot)
                            .frame(width: 6, height: 6)
                        Text(item.day)
                            .font(AuraTypography.mini)
                            .foregroundStyle(AuraColors.textSecondary)
                    }
                    Spacer()
                }
            }
        }
        .padding(AuraSpacing.large)
        .background(AuraColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AuraCorners.large))
        .shadow(color: Color.black.opacity(0.02), radius: 8, y: 4)
    }

    @ViewBuilder
    private var summaryCardsSection: some View {
        HStack(spacing: AuraSpacing.small) {
            summaryCard(
                icon: "face.smiling",
                iconColor: .green,
                value: "5.7",
                max: "/ 10",
                subtitle: "HUMOR PROM.",
                backgroundColor: Color(hex: "#E8FBF2")
            )
            summaryCard(
                icon: "moon.zzz.fill",
                iconColor: .blue,
                value: "7.0",
                max: "h",
                subtitle: "SUEÑO PROM.",
                backgroundColor: Color(hex: "#EAF2FF")
            )
            summaryCard(
                icon: "flame.fill",
                iconColor: altoColor,
                value: "4.9",
                max: "/ 10",
                subtitle: "ESTRÉS PROM.",
                backgroundColor: Color(hex: "#FFF2EC")
            )
        }
    }

    private func legendItem(color: Color, text: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(text)
                .font(AuraTypography.mini)
                .foregroundStyle(AuraColors.textSecondary)
        }
    }

    private func summaryCard(icon: String, iconColor: Color, value: String, max: String, subtitle: String, backgroundColor: Color) -> some View {
        VStack(alignment: .leading, spacing: AuraSpacing.small) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(iconColor)
                .padding(.bottom, 4)
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(AuraColors.textPrimary)
                Text(max)
                    .font(AuraTypography.mini)
                    .foregroundStyle(AuraColors.textSecondary)
            }
            
            Text(subtitle)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(AuraColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AuraSpacing.medium)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: AuraCorners.medium))
        .overlay(
            RoundedRectangle(cornerRadius: AuraCorners.medium)
                .stroke(AuraColors.cardStroke.opacity(0.3), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var diarioSection: some View {
        VStack(alignment: .leading, spacing: AuraSpacing.xLarge) {
            Text("Tus reflexiones diarias generadas por el consejero")
                .font(AuraTypography.footnote)
                .foregroundStyle(AuraColors.textSecondary)

            // AYER
            diarioCard(
                day: "AYER",
                icon: "face.dashed",
                iconColor: medioColor,
                completedActions: 1,
                totalActions: 3,
                text: "\"Noche difícil, mucha mente activa. Completé la respiración 4-7-8 pero me costó enfocarme.\""
            )
            
            // SÁBADO
            diarioCard(
                day: "SÁBADO",
                icon: "face.smiling",
                iconColor: bienestarColor,
                completedActions: 3,
                totalActions: 3,
                text: "\"Me sentí más tranquilo. La caminata matutina ayudó mucho a empezar el día con claridad.\""
            )
            
            // Prompt Card
            VStack(spacing: AuraSpacing.medium) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 28))
                    .foregroundStyle(AuraColors.primary)
                
                Text("¿Cómo te fue hoy?")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(AuraColors.textPrimary)
                
                Text("Tu consejero añadirá una reflexión al final del día")
                    .font(AuraTypography.footnote)
                    .foregroundStyle(AuraColors.textSecondary)
                
                Button {
                    // Acción
                } label: {
                    HStack {
                        Text("Hablar con mi consejero")
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(AuraColors.primary)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                    .background(AuraColors.primary.opacity(0.1))
                    .clipShape(Capsule())
                }
                .padding(.top, 8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AuraSpacing.xLarge)
            .padding(.horizontal, AuraSpacing.medium)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: AuraCorners.large))
            .overlay(
                RoundedRectangle(cornerRadius: AuraCorners.large)
                    .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                    .foregroundStyle(AuraColors.cardStroke)
            )
        }
    }

    private func diarioCard(day: String, icon: String, iconColor: Color, completedActions: Int, totalActions: Int, text: String) -> some View {
        VStack(alignment: .leading, spacing: AuraSpacing.medium) {
            HStack {
                Text(day)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(AuraColors.textSecondary)
                    .tracking(1)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: icon)
                        .foregroundStyle(iconColor)
                        .font(.system(size: 16))
                    Text("\(completedActions)/\(totalActions) acciones")
                        .font(AuraTypography.mini)
                        .foregroundStyle(AuraColors.textPrimary)
                }
            }
            
            Text(text)
                .font(AuraTypography.body.italic())
                .foregroundStyle(AuraColors.textPrimary)
                .lineSpacing(4)
            
            HStack(spacing: 4) {
                ForEach(0..<totalActions, id: \.self) { index in
                    Capsule()
                        .fill(index < completedActions ? bienestarColor : AuraColors.surfaceMuted)
                        .frame(height: 4)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 4)
        }
        .padding(AuraSpacing.large)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: AuraCorners.large))
        .shadow(color: Color.black.opacity(0.03), radius: 8, y: 4)
    }
}

struct EmotionSlice: View {
    let startAngle: Angle
    let endAngle: Angle
    let innerRadius: CGFloat
    let outerRadius: CGFloat
    let color: Color
    let text: String
    let textColor: Color
    
    var body: some View {
        ZStack {
            Path { path in
                let center = CGPoint(x: 150, y: 150)
                path.addArc(center: center, radius: outerRadius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
                path.addArc(center: center, radius: innerRadius, startAngle: endAngle, endAngle: startAngle, clockwise: true)
                path.closeSubpath()
            }
            .fill(color)
            .overlay(
                Path { path in
                    let center = CGPoint(x: 150, y: 150)
                    path.addArc(center: center, radius: outerRadius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
                    path.addArc(center: center, radius: innerRadius, startAngle: endAngle, endAngle: startAngle, clockwise: true)
                    path.closeSubpath()
                }
                .stroke(Color.white, lineWidth: 1.5)
            )

            // Colocación de los textos en coordenadas polares
            let midAngle = Angle(degrees: (startAngle.degrees + endAngle.degrees) / 2)
            let midRadius = (innerRadius + outerRadius) / 2
            let x = 150 + midRadius * cos(CGFloat(midAngle.radians))
            let y = 150 + midRadius * sin(CGFloat(midAngle.radians))
            
            let normalizedMid = (midAngle.degrees.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
            let rotation = normalizedMid + (normalizedMid > 90 && normalizedMid < 270 ? 180 : 0)
            
            Text(text)
                .font(.system(size: outerRadius > 100 ? 9 : (outerRadius > 60 ? 8 : 7), weight: .bold, design: .rounded))
                .foregroundColor(textColor)
                .rotationEffect(Angle(degrees: rotation))
                .position(x: x, y: y)
        }
    }
}

#Preview {
    NavigationStack {
        ProgressViewScreen()
    }
}
