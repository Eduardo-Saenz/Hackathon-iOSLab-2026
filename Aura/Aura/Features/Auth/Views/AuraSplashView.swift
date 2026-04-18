import SwiftUI

/// A cinematic entrance for the Aura app.
/// Orchestrates the brand logo drawing, typography reveal, and a fluid background transition.
struct AuraSplashView: View {
    @State private var logoProgress: CGFloat = 0
    @State private var textOpacity: Double = 0
    @State private var textTracking: CGFloat = 12
    
    // Background and foreground dynamically invert to bridge the app's default theme
    @State private var backgroundColor: Color = AuraColors.primary // Deep Teal
    @State private var foregroundColor: Color = Color(hex: "#EDE4D8") // Warm cream from the reference image
    @State private var shadowOpacity: Double = 1.0 // Fade out drop shadows when inverting
    
    @State private var logoScale: CGFloat = 0.85
    @State private var logoOffset: CGFloat = 10
    
    var onComplete: () -> Void = {}
    
    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: AuraSpacing.xLarge) {
                // To support fading the inner shadow we dynamically wrap or omit it
                BrandLogoView(progress: logoProgress, color: foregroundColor, size: 140)
                    .scaleEffect(logoScale)
                    .offset(y: logoOffset)
                    .shadow(color: Color.black.opacity(0.15 * shadowOpacity), radius: 4, y: 2) // Maintain subtle depth initially
                
                Text("Aura")
                    .font(AuraTypography.hero)
                    .foregroundStyle(foregroundColor)
                    .tracking(textTracking)
                    .opacity(textOpacity)
                    .blur(radius: (1 - textOpacity) * 8)
                    .offset(y: 10 * (1 - textOpacity))
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // 1. Draw Arcs sequentially from inside out
        withAnimation(AuraAnimations.logoDrawing) {
            logoProgress = 1.0
            logoScale = 1.0
            logoOffset = 0
        }
        
        // 2. Reveal Wordmark
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(AuraAnimations.calm.speed(0.8)) {
                textOpacity = 1.0
                textTracking = 2
            }
        }
        
        // 3. Fluid Color Shift to bridge into the main App Background
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            withAnimation(.easeInOut(duration: 0.8)) {
                backgroundColor = AuraColors.background
                foregroundColor = AuraColors.primary
                shadowOpacity = 0.0 // Flatten the aesthetic to match the RN flat look afterwards
            }
        }
        
        // 4. Complete and unmount
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
            onComplete()
        }
    }
}

#Preview {
    AuraSplashView()
}
