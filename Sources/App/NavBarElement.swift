import SwiftUI

struct NavBarElement: View {
    let item: RootView.CanvasItem
    @Binding var x: CGFloat
    @Binding var y: CGFloat
    @Binding var width: CGFloat
    
    let canvasSize: CGSize
    let isSelected: Bool
    var isPlayMode: Bool // 🎮 NEW: Receives Play Mode
    let onTapSelect: () -> Void
    let onDoubleTap: () -> Void
    let onGestureSelect: () -> Void

    @State private var dragStart: CGPoint = .zero
    @State private var activeTab: Int = 0

    var body: some View {
        // Standard iOS Default Navigation / Tab Bar
        TabView(selection: $activeTab) {
            ForEach(Array(item.navTabs.enumerated()), id: \.element.id) { index, tab in
                Color.clear
                    .tag(index)
                    // The actual default tab bar button
                    .tabItem {
                        Image(systemName: tab.icon)
                        Text(tab.title)
                    }
            }
        }
        .tint(item.color)
        .frame(width: width, height: 90)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        
        // Editor Selection Ring (Hidden in Play Mode)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke((isSelected && !isPlayMode) ? Color.blue : Color.clear, lineWidth: 2)
        )
        // Selection Gestures (Disabled in Play Mode)
        .simultaneousGesture(
            TapGesture(count: 2).onEnded {
                if !isPlayMode { onDoubleTap() }
            }
            .exclusively(before:
                TapGesture(count: 1).onEnded {
                    if !isPlayMode { onTapSelect() }
                }
            )
        )
        // Drag gesture for layout editor (Disabled in Play Mode)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .onChanged { g in
                    if isPlayMode { return } // 🔒 Lock movement in Play Mode
                    onGestureSelect()
                    if dragStart == .zero { dragStart = CGPoint(x: x, y: y) }
                    x = dragStart.x + g.translation.width
                    y = dragStart.y + g.translation.height
                }
                .onEnded { _ in
                    if isPlayMode { return }
                    dragStart = .zero
                }
        )
        .position(x: x, y: y)
    }
}

