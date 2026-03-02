import SwiftUI

struct GlassContainerElement: View {
    let item: RootView.CanvasItem
    @Binding var x: CGFloat
    @Binding var y: CGFloat
    @Binding var width: CGFloat
    @Binding var height: CGFloat

    let isSelected: Bool
    var isPlayMode: Bool
    let onTapSelect: () -> Void
    let onDoubleTap: () -> Void
    let onGestureSelect: () -> Void

    @State private var dragStart: CGPoint = .zero

    var body: some View {
        ZStack {
            // 1. The Deep Base Material
            RoundedRectangle(cornerRadius: item.cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)

            // 2. The Color Tint (Subtle)
            RoundedRectangle(cornerRadius: item.cornerRadius, style: .continuous)
                .fill(item.color.opacity(0.1))

            // 3. The Refractive Edge (Classic iOS 26 / Spatial Glass)
            RoundedRectangle(cornerRadius: item.cornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.5), .white.opacity(0.05), .black.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        }
        .frame(width: width, height: height)
        // Soft spatial drop shadow
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
        // Editor Selection Highlight
        .overlay(
            RoundedRectangle(cornerRadius: item.cornerRadius, style: .continuous)
                .stroke((isSelected && !isPlayMode) ? Color.blue : Color.clear, lineWidth: 2)
                .padding(-2)
        )
        // Gestures
        .simultaneousGesture(TapGesture(count: 2).onEnded { if !isPlayMode { onDoubleTap() } })
        .simultaneousGesture(TapGesture(count: 1).onEnded { if !isPlayMode { onTapSelect() } })
        .simultaneousGesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .onChanged { g in
                    if isPlayMode { return }
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
