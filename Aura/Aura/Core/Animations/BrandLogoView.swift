import SwiftUI

/// The iconic Aura brand mark: three concentric open arcs.
/// Matches the 3D embossed look and gap placement from the reference identity.
struct BrandLogoView: View {
    var progress: CGFloat = 1.0
    var color: Color = Color(hex: "#EDE4D8") // Warm cream
    var size: CGFloat = 120
    var lineWidth: CGFloat { size * 0.08 }
    
    var body: some View {
        ZStack {
            // Inner Arc (smallest)
            ArcShape(startAngle: .degrees(135), endAngle: .degrees(45))
                .trim(from: 0, to: staggeredProgress(base: progress, start: 0.0, end: 0.6))
                .stroke(
                    color, 
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size * 0.35, height: size * 0.35)
                .shadow(color: .black.opacity(0.15), radius: 2, x: 1, y: 1)
                .shadow(color: .white.opacity(0.3), radius: 1, x: -1, y: -1)

            // Middle Arc
            ArcShape(startAngle: .degrees(135), endAngle: .degrees(45))
                .trim(from: 0, to: staggeredProgress(base: progress, start: 0.2, end: 0.8))
                .stroke(
                    color, 
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size * 0.65, height: size * 0.65)
                .shadow(color: .black.opacity(0.15), radius: 2, x: 1, y: 1)
                .shadow(color: .white.opacity(0.3), radius: 1, x: -1, y: -1)

            // Outer Arc
            ArcShape(startAngle: .degrees(135), endAngle: .degrees(45))
                .trim(from: 0, to: staggeredProgress(base: progress, start: 0.4, end: 1.0))
                .stroke(
                    color, 
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size * 0.95, height: size * 0.95)
                .shadow(color: .black.opacity(0.15), radius: 2, x: 1, y: 1)
                .shadow(color: .white.opacity(0.3), radius: 1, x: -1, y: -1)
        }
        // Minimal scaling to simulate drawing "pop"
        .scaleEffect(progress < 0.1 ? 0.95 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: progress > 0.1)
    }
    
    private func staggeredProgress(base: CGFloat, start: CGFloat, end: CGFloat) -> CGFloat {
        if base <= start { return 0 }
        if base >= end { return 1 }
        return (base - start) / (end - start)
    }
}

private struct ArcShape: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var clockwise: Bool = false
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: rect.width / 2,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: clockwise
        )
        return path
    }
}

#Preview {
    ZStack {
        AuraColors.primary.ignoresSafeArea()
        VStack(spacing: 50) {
            BrandLogoView(progress: 1.0)
            BrandLogoView(progress: 0.5)
        }
    }
}
