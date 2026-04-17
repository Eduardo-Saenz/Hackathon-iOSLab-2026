import SwiftUI

struct ChartDataPoint {
    let day: String
    let fill: Double
    let dot: Color
}

struct EmotionBranch: Identifiable {
    let id = UUID()
    let primary: String
    let secondary: [String]
    let tertiaryBySecondary: [String: [String]]
    let color: Color
}

@MainActor
struct ProgressViewScreen: View {
    @StateObject private var viewModel: ProgressScreenViewModel
    @State private var selectedTab = "Diario"
    @State private var animateBars = false

    @State private var selectedPrimaryIndex: Int? = nil
    @State private var selectedSecondary: String? = nil
    @State private var selectedTertiary: String? = nil
    @State private var revealedEmotionLevel: Int = 1
    @State private var sentEmotionMessage: String? = nil

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

    private let emotionBranches: [EmotionBranch] = [
        EmotionBranch(
            primary: "IRA",
            secondary: ["Herido", "Amenazado", "Lleno de odio", "Loco", "Agresivo", "Frustrado", "Distante", "Crítico"],
            tertiaryBySecondary: [
                "Herido": ["Apenado", "Devastado", "Atacado"],
                "Amenazado": ["Celoso", "Resentido", "Ultrajado"],
                "Lleno de odio": ["Furioso", "Rabioso", "Provocador"],
                "Loco": ["Hostil", "Enfurecido", "Irritado"],
                "Agresivo": ["Introvertido", "Desconfiado", "Escéptico"],
                "Frustrado": ["Sarcástico"],
                "Distante": ["Reservado"],
                "Crítico": ["Juzgador"]
            ],
            color: Color(hex: "#F3B4B8")
        ),
        EmotionBranch(
            primary: "ASCO",
            secondary: ["Disconforme", "Decepcionado", "Horrible", "Abstinencia"],
            tertiaryBySecondary: [
                "Disconforme": ["Moralista", "Reacio"],
                "Decepcionado": ["Repugnante", "Revoltoso"],
                "Horrible": ["Asco", "Odioso"],
                "Abstinencia": ["Aversión", "Vacilante"]
            ],
            color: Color(hex: "#BFEFDE")
        ),
        EmotionBranch(
            primary: "TRISTEZA",
            secondary: ["Culpable", "Abandonado", "Desesperado", "Deprimido", "Solo", "Aburrido"],
            tertiaryBySecondary: [
                "Culpable": ["Arrepentido", "Avergonzado"],
                "Abandonado": ["Ignorado", "Victimizado"],
                "Desesperado": ["Desvalido", "Vulnerable"],
                "Deprimido": ["Melancólico", "Vacío"],
                "Solo": ["Desamparado", "Aislado"],
                "Aburrido": ["Apático", "Indiferente"]
            ],
            color: Color(hex: "#E4D6F7")
        ),
        EmotionBranch(
            primary: "FELICIDAD",
            secondary: ["Íntimo", "Optimista", "Sensible", "Abierto", "Inspirado", "Indiferente", "Poderoso", "Aceptado", "Orgulloso", "Interesado", "Alegre"],
            tertiaryBySecondary: [
                "Íntimo": ["Cariñoso"],
                "Optimista": ["Esperanzado"],
                "Sensible": ["Bromista"],
                "Abierto": ["Abierto"],
                "Inspirado": ["Inspirado"],
                "Indiferente": ["Curioso"],
                "Poderoso": ["Importante", "Seguro"],
                "Aceptado": ["Respetado", "Satisfecho"],
                "Orgulloso": ["Valiente", "Provocativo"],
                "Interesado": ["Valioso"],
                "Alegre": ["Entusiasta", "Energético", "Liberado", "Eufórico"]
            ],
            color: Color(hex: "#F5CF8C")
        ),
        EmotionBranch(
            primary: "SORPRESA",
            secondary: ["Sorprendido", "Confundido", "Asombrado"],
            tertiaryBySecondary: [
                "Sorprendido": ["Conmocionado"],
                "Confundido": ["Abatido", "Desilusionado", "Perplejo"],
                "Asombrado": ["Estupefacto", "Impresionado", "Entusiasta"]
            ],
            color: Color(hex: "#F2F2A7")
        ),
        EmotionBranch(
            primary: "MIEDO",
            secondary: ["Asustado", "Ansioso", "Inseguro", "Sumiso", "Rechazado", "Humillado"],
            tertiaryBySecondary: [
                "Asustado": ["Aterrado", "Espantado", "Agobiado", "Preocupado"],
                "Ansioso": ["Insuficiente", "Inferior"],
                "Inseguro": ["Inútil", "Insignificante"],
                "Sumiso": ["Marginado", "Alienado"],
                "Rechazado": ["Irrespetado", "Ridiculizado"],
                "Humillado": ["Apenado"]
            ],
            color: Color(hex: "#E2E2E2")
        )
    ]

    init() {
        _viewModel = StateObject(wrappedValue: ProgressScreenViewModel())
    }

    init(viewModel: ProgressScreenViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    private var selectedPrimaryBranch: EmotionBranch? {
        guard let selectedPrimaryIndex else { return nil }
        return emotionBranches[selectedPrimaryIndex]
    }

    private var visibleSecondaryOptions: [String] {
        selectedPrimaryBranch?.secondary ?? []
    }

    private var visibleTertiaryOptions: [String] {
        guard let selectedPrimaryBranch, let selectedSecondary else { return [] }
        return selectedPrimaryBranch.tertiaryBySecondary[selectedSecondary] ?? []
    }

    private var canSendEmotion: Bool {
        selectedPrimaryBranch != nil
    }

    private var currentEmotionPayload: String {
        var parts: [String] = []
        if let primary = selectedPrimaryBranch?.primary { parts.append(primary) }
        if let selectedSecondary { parts.append(selectedSecondary) }
        if let selectedTertiary { parts.append(selectedTertiary) }
        return parts.joined(separator: " → ")
    }

    private var level1Scale: CGFloat {
        switch revealedEmotionLevel {
        case 1: return 1.0
        case 2: return 0.58
        default: return 0.40
        }
    }

    private var level2Scale: CGFloat {
        switch revealedEmotionLevel {
        case 2: return 1.03
        case 3: return 0.60
        default: return 0.0
        }
    }

    private var level3Scale: CGFloat {
        revealedEmotionLevel >= 3 ? 1.05 : 0.0
    }

    private var level1Opacity: Double {
        switch revealedEmotionLevel {
        case 1: return 1.0
        case 2: return 0.32
        default: return 0.14
        }
    }

    private var level2Opacity: Double {
        switch revealedEmotionLevel {
        case 2: return 1.0
        case 3: return 0.30
        default: return 0.0
        }
    }

    private var level3Opacity: Double {
        revealedEmotionLevel >= 3 ? 1.0 : 0.0
    }

    private var level1OffsetY: CGFloat {
        switch revealedEmotionLevel {
        case 1: return 0
        case 2: return 10
        default: return 18
        }
    }

    private var level2OffsetY: CGFloat {
        switch revealedEmotionLevel {
        case 2: return -4
        case 3: return 10
        default: return 0
        }
    }

    private var level3OffsetY: CGFloat {
        revealedEmotionLevel >= 3 ? -8 : 0
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
            if selectedTab == "Mapa" {
                resetEmotionMap(animated: false)
            }
        }
        .onChange(of: selectedTab) { newValue in
            if newValue == "Semana" {
                withAnimation { animateBars = true }
            } else {
                animateBars = false
            }

            if newValue == "Mapa" {
                resetEmotionMap(animated: true)
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

                Text("Primero aparecen las emociones centrales. Luego profundiza paso a paso tocando cada nivel.")
                    .font(AuraTypography.footnote)
                    .foregroundStyle(AuraColors.textSecondary)
                    .lineSpacing(3)
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
        VStack(spacing: AuraSpacing.large) {
            HStack(spacing: AuraSpacing.small) {

                Button {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                        resetEmotionMap(animated: false)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reiniciar")
                    }
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(AuraColors.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(AuraColors.primary.opacity(0.10))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white,
                                AuraColors.surfaceMuted.opacity(0.58)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 320, height: 320)
                    .shadow(color: Color.black.opacity(0.03), radius: 14, y: 8)

                if revealedEmotionLevel >= 1 {
                    primaryWheel
                        .scaleEffect(level1Scale)
                        .opacity(level1Opacity)
                        .offset(y: level1OffsetY)
                        .animation(.spring(response: 0.52, dampingFraction: 0.84), value: revealedEmotionLevel)
                }

                if revealedEmotionLevel >= 2 {
                    secondaryWheel
                        .scaleEffect(level2Scale)
                        .opacity(level2Opacity)
                        .offset(y: level2OffsetY)
                        .animation(.spring(response: 0.52, dampingFraction: 0.84), value: revealedEmotionLevel)
                }

                if revealedEmotionLevel >= 3 {
                    tertiaryWheel
                        .scaleEffect(level3Scale)
                        .opacity(level3Opacity)
                        .offset(y: level3OffsetY)
                        .animation(.spring(response: 0.52, dampingFraction: 0.84), value: revealedEmotionLevel)
                        .transition(.scale(scale: 0.92).combined(with: .opacity))
                }

                centerEmotionBadge
            }
            .frame(width: 320, height: 320)
            .frame(maxWidth: .infinity)
            .clipped()

            VStack(alignment: .leading, spacing: AuraSpacing.small) {
                Text(emotionSelectionTitle)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(AuraColors.textPrimary)

                Text(emotionSelectionSubtitle)
                    .font(AuraTypography.footnote)
                    .foregroundStyle(AuraColors.textSecondary)
                    .lineSpacing(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if revealedEmotionLevel == 1 {
                emotionChipGrid(
                    title: "Emociones centrales",
                    items: emotionBranches.map(\.primary),
                    selectedItem: selectedPrimaryBranch?.primary,
                    color: nil
                ) { item in
                    guard let index = emotionBranches.firstIndex(where: { $0.primary == item }) else { return }
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.84)) {
                        selectedPrimaryIndex = index
                        selectedSecondary = nil
                        selectedTertiary = nil
                        revealedEmotionLevel = 2
                    }
                }
            } else if revealedEmotionLevel == 2 {
                emotionChipGrid(
                    title: "Elige un matiz",
                    items: visibleSecondaryOptions,
                    selectedItem: selectedSecondary,
                    color: selectedPrimaryBranch?.color
                ) { item in
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.84)) {
                        selectedSecondary = item
                        selectedTertiary = nil
                        revealedEmotionLevel = 3
                    }
                }
            } else {
                emotionChipGrid(
                    title: "También puedes elegir desde abajo",
                    items: visibleTertiaryOptions,
                    selectedItem: selectedTertiary,
                    color: selectedPrimaryBranch?.color
                ) { item in
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.84)) {
                        selectedTertiary = item
                    }
                }
            }

            if canSendEmotion {
                VStack(spacing: AuraSpacing.small) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill((selectedPrimaryBranch?.color ?? AuraColors.primary).opacity(0.95))
                            .frame(width: 10, height: 10)

                        Text(currentEmotionPayload.isEmpty ? "Selecciona una emoción" : currentEmotionPayload)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(AuraColors.textPrimary)
                            .lineLimit(2)

                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: AuraCorners.medium))
                    .overlay(
                        RoundedRectangle(cornerRadius: AuraCorners.medium)
                            .stroke(AuraColors.cardStroke.opacity(0.28), lineWidth: 1)
                    )

                    Button {
                        sentEmotionMessage = currentEmotionPayload
                    } label: {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text("Enviar emoción")
                        }
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(canSendEmotion ? AuraColors.primary : AuraColors.surfaceMuted)
                        .clipShape(RoundedRectangle(cornerRadius: AuraCorners.medium))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSendEmotion)

                    if let sentEmotionMessage {
                        Text("Enviado: \(sentEmotionMessage)")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(AuraColors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }

    private var primaryWheel: some View {
        ZStack {
            ForEach(Array(emotionBranches.enumerated()), id: \.offset) { index, branch in
                let angles = anglesForSegment(index: index, total: emotionBranches.count)

                EmotionWheelButtonSegment(
                    startAngle: angles.start,
                    endAngle: angles.end,
                    innerRadius: 42,
                    outerRadius: 126,
                    fillColor: branch.color.opacity(selectedPrimaryIndex == index ? 0.98 : 0.82),
                    strokeColor: .white,
                    text: branch.primary,
                    textColor: AuraColors.textPrimary,
                    fontSize: 11,
                    isSelected: selectedPrimaryIndex == index
                ) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.84)) {
                        selectedPrimaryIndex = index
                        selectedSecondary = nil
                        selectedTertiary = nil
                        revealedEmotionLevel = 2
                        sentEmotionMessage = nil
                    }
                }
            }
        }
        .frame(width: 260, height: 260)
    }

    @ViewBuilder
    private var secondaryWheel: some View {
        if let selectedPrimaryIndex,
           let branch = emotionBranches[safe: selectedPrimaryIndex] {
            ZStack {
                ForEach(Array(branch.secondary.enumerated()), id: \.offset) { secondaryIndex, secondary in
                    let angles = anglesForSegment(index: secondaryIndex, total: branch.secondary.count)

                    EmotionWheelButtonSegment(
                        startAngle: angles.start,
                        endAngle: angles.end,
                        innerRadius: 46,
                        outerRadius: 146,
                        fillColor: branch.color.opacity(selectedSecondary == secondary ? 0.98 : 0.62),
                        strokeColor: .white,
                        text: secondary.uppercased(),
                        textColor: AuraColors.textPrimary,
                        fontSize: 8.7,
                        isSelected: selectedSecondary == secondary
                    ) {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.84)) {
                            selectedSecondary = secondary
                            selectedTertiary = nil
                            revealedEmotionLevel = 3
                            sentEmotionMessage = nil
                        }
                    }
                }
            }
            .frame(width: 300, height: 300)
        }
    }

    @ViewBuilder
    private var tertiaryWheel: some View {
        if let selectedPrimaryBranch,
           let selectedSecondary {
            let items = selectedPrimaryBranch.tertiaryBySecondary[selectedSecondary] ?? []

            ZStack {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    let angles = anglesForSegment(index: index, total: max(items.count, 1))

                    EmotionWheelButtonSegment(
                        startAngle: angles.start,
                        endAngle: angles.end,
                        innerRadius: 54,
                        outerRadius: 154,
                        fillColor: selectedPrimaryBranch.color.opacity(selectedTertiary == item ? 0.98 : 0.68),
                        strokeColor: .white,
                        text: item.uppercased(),
                        textColor: AuraColors.textPrimary,
                        fontSize: 9,
                        isSelected: selectedTertiary == item
                    ) {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.84)) {
                            selectedTertiary = item
                            sentEmotionMessage = nil
                        }
                    }
                }
            }
            .frame(width: 300, height: 300)
        }
    }

    private var centerEmotionBadge: some View {
        Circle()
            .fill(AuraColors.surface)
            .frame(width: 76, height: 76)
            .shadow(color: Color.black.opacity(0.08), radius: 6, y: 3)
            .overlay(
                VStack(spacing: 2) {
                    Text(selectedPrimaryBranch?.primary ?? "YO")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(AuraColors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    if let selectedSecondary {
                        Text(selectedSecondary)
                            .font(.system(size: 8, weight: .medium, design: .rounded))
                            .foregroundStyle(AuraColors.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }

                    if let selectedTertiary {
                        Text(selectedTertiary)
                            .font(.system(size: 7, weight: .medium, design: .rounded))
                            .foregroundStyle(AuraColors.textSecondary.opacity(0.9))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                .padding(.horizontal, 6)
            )
            .animation(.spring(response: 0.45, dampingFraction: 0.84), value: revealedEmotionLevel)
    }

    private var emotionSelectionTitle: String {
        if let tertiary = selectedTertiary, let primary = selectedPrimaryBranch?.primary, let secondary = selectedSecondary {
            return "Elegiste: \(primary) → \(secondary) → \(tertiary)"
        } else if let primary = selectedPrimaryBranch?.primary, let secondary = selectedSecondary {
            return "Estás explorando: \(primary) → \(secondary)"
        } else if let primary = selectedPrimaryBranch?.primary {
            return "Seleccionaste: \(primary)"
        } else {
            return "Empieza por la emoción más central"
        }
    }

    private var emotionSelectionSubtitle: String {
        if revealedEmotionLevel == 1 {
            return "Toca una emoción central dentro de la rueda o en los botones de abajo."
        } else if revealedEmotionLevel == 2 {
            return "Ahora enfócate en el segundo nivel. El anterior baja de opacidad para ayudarte a elegir."
        } else {
            return "El último nivel aparece dentro de la rueda y toma protagonismo arriba."
        }
    }

    private func emotionChipGrid(
        title: String,
        items: [String],
        selectedItem: String?,
        color: Color?,
        action: @escaping (String) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: AuraSpacing.small) {
            Text(title)
                .font(AuraTypography.mini)
                .foregroundStyle(AuraColors.textSecondary)
                .tracking(1)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AuraSpacing.small), count: 2), spacing: AuraSpacing.small) {
                ForEach(items, id: \.self) { item in
                    Button {
                        action(item)
                    } label: {
                        HStack(spacing: 8) {
                            Circle()
                                .fill((color ?? AuraColors.primary).opacity(0.95))
                                .frame(width: 8, height: 8)

                            Text(item)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(AuraColors.textPrimary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)

                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                        .background(selectedItem == item ? (color ?? AuraColors.primary).opacity(0.18) : Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: AuraCorners.medium))
                        .overlay(
                            RoundedRectangle(cornerRadius: AuraCorners.medium)
                                .stroke(
                                    selectedItem == item
                                    ? (color ?? AuraColors.primary).opacity(0.55)
                                    : AuraColors.cardStroke.opacity(0.28),
                                    lineWidth: selectedItem == item ? 1.5 : 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func emotionStepPill(title: String, isActive: Bool) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(isActive ? AuraColors.textPrimary : AuraColors.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(isActive ? Color.white : AuraColors.surfaceMuted.opacity(0.8))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(AuraColors.cardStroke.opacity(isActive ? 0.25 : 0.12), lineWidth: 1)
            )
    }

    private func resetEmotionMap(animated: Bool) {
        let action = {
            selectedPrimaryIndex = nil
            selectedSecondary = nil
            selectedTertiary = nil
            revealedEmotionLevel = 1
            sentEmotionMessage = nil
        }

        if animated {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                action()
            }
        } else {
            action()
        }
    }

    private func anglesForSegment(index: Int, total: Int) -> (start: Angle, end: Angle) {
        let step = 360.0 / Double(total)
        let start = (Double(index) * step) - 90.0
        let end = start + step
        return (Angle(degrees: start), Angle(degrees: end))
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

            diarioCard(
                day: "AYER",
                icon: "face.dashed",
                iconColor: medioColor,
                completedActions: 1,
                totalActions: 3,
                text: "\"Noche difícil, mucha mente activa. Completé la respiración 4-7-8 pero me costó enfocarme.\""
            )

            diarioCard(
                day: "SÁBADO",
                icon: "face.smiling",
                iconColor: bienestarColor,
                completedActions: 3,
                totalActions: 3,
                text: "\"Me sentí más tranquilo. La caminata matutina ayudó mucho a empezar el día con claridad.\""
            )

            VStack(spacing: AuraSpacing.medium) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 28))
                    .foregroundStyle(AuraColors.primary)

                Text("¿Cómo te fue hoy?")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(AuraColors.textPrimary)

                Text("Abre tu coach para escribir o hablar sobre tu diario de hoy.")
                    .font(AuraTypography.footnote)
                    .foregroundStyle(AuraColors.textSecondary)

                NavigationLink {
                    CoachView(entryMessage: "Esto es para mi diario")
                } label: {
                    HStack {
                        Text("Ir a mi coach")
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(AuraColors.primary)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                    .background(AuraColors.primary.opacity(0.1))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
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

struct EmotionWheelButtonSegment: View {
    let startAngle: Angle
    let endAngle: Angle
    let innerRadius: CGFloat
    let outerRadius: CGFloat
    let fillColor: Color
    let strokeColor: Color
    let text: String
    let textColor: Color
    let fontSize: CGFloat
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                EmotionArcShape(
                    startAngle: startAngle,
                    endAngle: endAngle,
                    innerRadius: innerRadius,
                    outerRadius: outerRadius
                )
                .fill(fillColor)
                .overlay(
                    EmotionArcShape(
                        startAngle: startAngle,
                        endAngle: endAngle,
                        innerRadius: innerRadius,
                        outerRadius: outerRadius
                    )
                    .stroke(strokeColor, lineWidth: isSelected ? 2.2 : 1.2)
                )
                .shadow(color: isSelected ? fillColor.opacity(0.35) : .clear, radius: 8, y: 3)

                EmotionSegmentText(
                    text: text,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    innerRadius: innerRadius,
                    outerRadius: outerRadius,
                    textColor: textColor,
                    fontSize: fontSize
                )
            }
            .contentShape(
                EmotionArcShape(
                    startAngle: startAngle,
                    endAngle: endAngle,
                    innerRadius: innerRadius,
                    outerRadius: outerRadius
                )
            )
        }
        .buttonStyle(.plain)
    }
}

struct EmotionArcShape: Shape {
    let startAngle: Angle
    let endAngle: Angle
    let innerRadius: CGFloat
    let outerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)

        var path = Path()
        path.addArc(center: center, radius: outerRadius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.addArc(center: center, radius: innerRadius, startAngle: endAngle, endAngle: startAngle, clockwise: true)
        path.closeSubpath()
        return path
    }
}

struct EmotionSegmentText: View {
    let text: String
    let startAngle: Angle
    let endAngle: Angle
    let innerRadius: CGFloat
    let outerRadius: CGFloat
    let textColor: Color
    let fontSize: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            let midAngle = Angle(degrees: (startAngle.degrees + endAngle.degrees) / 2)
            let textRadius = (innerRadius + outerRadius) / 2
            let x = center.x + textRadius * cos(CGFloat(midAngle.radians))
            let y = center.y + textRadius * sin(CGFloat(midAngle.radians))

            let normalized = (midAngle.degrees.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
            let rotation = normalized > 90 && normalized < 270 ? normalized + 180 : normalized

            Text(text)
                .font(.system(size: fontSize, weight: .bold, design: .rounded))
                .foregroundStyle(textColor)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
                .rotationEffect(.degrees(rotation))
                .position(x: x, y: y)
        }
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    NavigationStack {
        ProgressViewScreen()
    }
}
