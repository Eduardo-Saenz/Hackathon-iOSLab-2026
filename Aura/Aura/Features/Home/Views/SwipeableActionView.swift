import SwiftUI

/// Adds a premium, elastic swipe-to-complete gesture to habit cards.
struct SwipeableActionView<Content: View>: View {
    let isCompleted: Bool
    let onComplete: () -> Void
    @ViewBuilder let content: () -> Content
    
    @State private var swipeOffset: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    private let completionThreshold: CGFloat = 100
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Background Success Reveal
            RoundedRectangle(cornerRadius: AuraCorners.large)
                .fill(
                    LinearGradient(
                        colors: [AuraColors.successSoft, AuraColors.primary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.white)
                            .scaleEffect(swipeOffset > completionThreshold ? 1.2 : 0.8)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: swipeOffset > completionThreshold)
                        Spacer()
                    }
                    .padding(.leading, AuraSpacing.xLarge)
                )
                .opacity(isCompleted ? 0 : (swipeOffset > 20 ? 1 : 0))
            
            // Foregound Card
            content()
                .background(AuraColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: AuraCorners.large))
                .overlay(
                    RoundedRectangle(cornerRadius: AuraCorners.large)
                        .stroke(AuraColors.cardStroke.opacity(0.3), lineWidth: 1)
                )
                .offset(x: isCompleted ? 0 : swipeOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            guard !isCompleted else { return }
                            if value.translation.width > 0 {
                                // Add elastic resistance
                                let factor = log10(value.translation.width + 1) * 30
                                swipeOffset = factor
                                
                                if swipeOffset > completionThreshold && swipeOffset < completionThreshold + 5 {
                                    AuraHaptics.rigid() // Notch feeling when threshold is reached
                                }
                            }
                        }
                        .onEnded { value in
                            guard !isCompleted else { return }
                            if swipeOffset > completionThreshold {
                                AuraHaptics.success()
                                withAnimation(AuraAnimations.cardSnap) {
                                    swipeOffset = 500 // Swipe all the way out
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    onComplete()
                                    swipeOffset = 0 // Reset behind the scenes
                                }
                            } else {
                                withAnimation(AuraAnimations.liquidSpring) {
                                    swipeOffset = 0
                                }
                            }
                        }
                )
                .animation(reduceMotion ? .default : .interactiveSpring(), value: swipeOffset)
        }
    }
}
