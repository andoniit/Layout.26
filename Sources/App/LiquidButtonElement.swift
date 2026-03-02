import SwiftUI
#if os(iOS)
import UIKit
#endif

struct LiquidButtonElement: View {
    let item: RootView.CanvasItem
    @Binding var x: CGFloat
    @Binding var y: CGFloat
    
    let isSelected: Bool
    var isPlayMode: Bool
    let onTapSelect: () -> Void
    let onDoubleTap: () -> Void
    let onGestureSelect: () -> Void

    @State private var dragStart: CGPoint = .zero

    var body: some View {
        if isPlayMode {
            // 1. PLAY MODE: Real interactive button with push physics
            Button {
                // Trigger action when pressed in play mode!
                #if os(iOS)
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                #endif
                print("\(item.text.isEmpty ? "Icon" : item.text) Button Tapped!")
            } label: {
                glassContent
            }
            .buttonStyle(GlassPushStyle()) // Applies the squish effect
            .position(x: x, y: y)
            
        } else {
            // 2. EDITOR MODE: Solid element for dragging and selecting
            glassContent
                // Editor Selection Highlight
                .overlay(
                    Capsule(style: .continuous)
                        .stroke((isSelected && !isPlayMode) ? Color.blue : Color.clear, lineWidth: 2)
                        .padding(-2)
                )
                .simultaneousGesture(
                    TapGesture(count: 2).onEnded { onDoubleTap() }
                )
                .simultaneousGesture(
                    TapGesture(count: 1).onEnded { onTapSelect() }
                )
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .global)
                        .onChanged { g in
                            onGestureSelect()
                            if dragStart == .zero { dragStart = CGPoint(x: x, y: y) }
                            x = dragStart.x + g.translation.width
                            y = dragStart.y + g.translation.height
                        }
                        .onEnded { _ in dragStart = .zero }
                )
                .position(x: x, y: y)
        }
    }
    
    // 3. THE VISUAL DESIGN (Shared between Editor and Play modes)
    private var glassContent: some View {
        let isIconOnly = item.buttonMode == 1
        let circleSize = max(54, item.fontSize * 2.2)
        
        return HStack(spacing: 8) {
            if !item.icon.isEmpty && (item.buttonMode == 0 || item.buttonMode == 1) {
                Image(systemName: item.icon)
                    .font(.system(size: max(18, item.fontSize * 0.9), weight: .medium))
            }
            
            if item.buttonMode == 0 || item.buttonMode == 2 {
                Text(item.text)
                    .font(.system(size: item.fontSize, weight: .medium))
            }
        }
        .padding(.horizontal, isIconOnly ? 0 : 24)
        .padding(.vertical, isIconOnly ? 0 : 14)
        .frame(width: isIconOnly ? circleSize : nil, height: isIconOnly ? circleSize : nil)
        .foregroundStyle(item.color)
        .background(
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .background(
            Capsule(style: .continuous)
                .fill(item.color.opacity(0.15))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.8), .white.opacity(0.1), item.color.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
        )
        .shadow(color: item.color.opacity(0.2), radius: 12, y: 4)
    }
}

// 4. THE PUSHABLE PHYSICS
struct GlassPushStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            // Apple's signature fluid scale down when pressed
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            // Slight dimming effect
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            // Spring animation for the bounce back
            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
