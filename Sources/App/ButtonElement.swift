import SwiftUI

struct ButtonElement: View {
    let item: RootView.CanvasItem
    @Binding var x: CGFloat
    @Binding var y: CGFloat
    @Binding var width: CGFloat
    
    let canvasSize: CGSize
    var isPlayMode: Bool
    let isSelected: Bool
    let onTapSelect: () -> Void
    let onDoubleTap: () -> Void
    let onGestureSelect: () -> Void

    @State private var dragStart: CGPoint = .zero
    @State private var isPressed: Bool = false

    var body: some View {
        HStack(spacing: item.buttonMode == 0 ? 8 : 0) {
            if item.buttonMode == 0 || item.buttonMode == 1 {
                Image(systemName: item.icon)
                    .font(.system(size: item.fontSize))
            }
            if item.buttonMode == 0 || item.buttonMode == 2 {
                Text(item.text)
                    .font(.system(size: item.fontSize, weight: item.isBold ? .bold : .medium))
            }
        }
        .foregroundStyle(item.color)
        .padding(.horizontal, item.buttonMode == 1 ? 16 : 24)
        .padding(.vertical, 16)
        .background(
            Group {
                if item.isGlass {
                    Capsule().fill(.ultraThinMaterial)
                } else {
                    Capsule().fill(Color.primary.opacity(0.1))
                }
            }
        )
        .overlay(
            Capsule().stroke((isSelected && !isPlayMode) ? Color.blue : Color.primary.opacity(0.1), lineWidth: (isSelected && !isPlayMode) ? 2 : 1)
        )
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .contentShape(Capsule())
        .gesture(
            TapGesture(count: 2).onEnded { if !isPlayMode { onDoubleTap() } }
            .exclusively(before: TapGesture(count: 1).onEnded { if !isPlayMode { onTapSelect() } })
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .onChanged { g in
                    if isPlayMode { return }
                    if !isPressed { isPressed = true }
                    onGestureSelect()
                    if dragStart == .zero { dragStart = CGPoint(x: x, y: y) }
                    x = dragStart.x + g.translation.width
                    y = dragStart.y + g.translation.height
                }
                .onEnded { _ in
                    if isPlayMode { return }
                    isPressed = false
                    dragStart = .zero
                }
        )
        .position(x: x, y: y)
    }
}

