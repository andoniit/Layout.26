import SwiftUI

struct SliderElement: View {
    let item: RootView.CanvasItem
    @Binding var x: CGFloat
    @Binding var y: CGFloat
    @Binding var value: Double
    
    let isSelected: Bool
    var isPlayMode: Bool
    let onTapSelect: () -> Void
    let onGestureSelect: () -> Void

    @State private var dragStart: CGPoint = .zero

    var body: some View {
        Slider(value: $value, in: 0...1)
            .tint(item.color)
            .labelsHidden()
            .frame(width: item.width)
            .padding(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke((isSelected && !isPlayMode) ? Color.blue : Color.clear, lineWidth: 2)
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .onChanged { g in
                        if isPlayMode { return }
                        onGestureSelect()
                        if dragStart == .zero { dragStart = CGPoint(x: x, y: y) }
                        x = dragStart.x + g.translation.width
                        y = dragStart.y + g.translation.height
                    }
                    .onEnded { _ in 
                        dragStart = .zero 
                    }
            )
            .simultaneousGesture(
                TapGesture().onEnded { 
                    if !isPlayMode { onTapSelect() } 
                }
            )
            .position(x: x, y: y)
    }
}
