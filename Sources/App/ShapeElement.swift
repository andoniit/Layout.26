import SwiftUI

struct ShapeElement: View {
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
        Group {
            if item.shapeType == 1 {
                // CIRCLE
                Circle()
                    .fill(item.isGlass ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(item.color))
                    .opacity(item.isGlass ? 1.0 : item.opacity)
                    .overlay(glassOverlay(shape: Circle()))
            } else {
                // RECTANGLE / SQUARE
                RoundedRectangle(cornerRadius: item.cornerRadius, style: .continuous)
                    .fill(item.isGlass ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(item.color))
                    .opacity(item.isGlass ? 1.0 : item.opacity)
                    .overlay(glassOverlay(shape: RoundedRectangle(cornerRadius: item.cornerRadius, style: .continuous)))
            }
        }
        .frame(width: width, height: item.shapeType == 1 ? width : height)
        .overlay(
            Group {
                if item.shapeType == 1 {
                    Circle()
                        .stroke((isSelected && !isPlayMode) ? Color.blue : Color.clear, lineWidth: 2)
                        .padding(-2)
                } else {
                    RoundedRectangle(cornerRadius: item.cornerRadius, style: .continuous)
                        .stroke((isSelected && !isPlayMode) ? Color.blue : Color.clear, lineWidth: 2)
                        .padding(-2)
                }
            }
        )
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

    @ViewBuilder
    private func glassOverlay<S: InsettableShape>(shape: S) -> some View {
        if item.isGlass {
            shape
                .fill(item.color.opacity(item.opacity * 0.3))
                .overlay(
                    shape.strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.6), .clear, item.color.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                )
        }
    }
}

