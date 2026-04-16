import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

enum AuraColors {
    static let background = Color(hex: "#F5F3ED") // Lino Fresco / Fondo Base
    static let surface = Color(hex: "#FFFFFF") // Brillante / Tarjetas de Superficie
    static let surfaceMuted = Color(hex: "#F5F3ED").opacity(0.9)
    static let cardStroke = Color(hex: "#EDE6E9") // Cool-Tinted shadows/strokes
    
    static let primary = Color(hex: "#0A485A") // Teal Profundo / Marca Principal
    static let primaryDark = Color(hex: "#0A485A")
    static let secondary = Color(hex: "#3D5A6C") // Teal Pizarra
    static let tertiary = Color(hex: "#C4B6DB") // Lavanda
    static let textPrimary = Color(hex: "#0A485A") // H1, headers
    static let textSecondary = Color(hex: "#3D5A6C") // Teal Pizarra / Texto Secundario
    static let textTertiary = Color.gray.opacity(0.6)
    
    static let accentMint = Color(hex: "#A1E3D6") // Menta Aurora
    static let accentLavender = Color(hex: "#C4B6DB") // Lavanda Silenciada
    static let shadowCool = Color(hex: "#EDE6E9") // Sombras
    
    // Status and pills
    static let successSoft = Color(hex: "#A1E3D6").opacity(0.4)
    static let blueSoft = Color(hex: "#C4B6DB").opacity(0.4)
    static let orangeSoft = Color(hex: "#A1E3D6").opacity(0.4)
    static let pillBackground = Color(hex: "#EDE6E9").opacity(0.6)
}
