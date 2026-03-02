import SwiftUI

struct ToggleElement: View {
    let item: RootView.CanvasItem 
    @Binding var x: CGFloat
    @Binding var y: CGFloat
    @Binding var isOn: Bool
    
    let isSelected: Bool
    var isPlayMode: Bool
    let onTapSelect: () -> Void
    let onGestureSelect: () -> Void

    @State private var dragStart: CGPoint = .zero

    var body: some View {
        Toggle("", isOn: $isOn)
            .labelsHidden()
            .toggleStyle(SwitchToggleStyle(tint: item.color))
            .frame(width: 51, height: 31)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke((isSelected && !isPlayMode) ? Color.blue : Color.clear, lineWidth: 2)
                    .scaleEffect(1.2)
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
