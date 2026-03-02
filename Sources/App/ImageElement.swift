import SwiftUI
#if os(iOS)
import UIKit
#endif

struct ImageElement: View {
    let id: UUID
    let uiImage: UIImage

    @Binding var x: CGFloat
    @Binding var y: CGFloat
    @Binding var width: CGFloat
    @Binding var height: CGFloat
    @Binding var shapeIndex: Int 
    @Binding var filterIndex: Int // NEW

    let canvasSize: CGSize
    let isSelected: Bool
    var isPlayMode: Bool
    let onTapSelect: () -> Void
    let onDoubleTap: () -> Void
    let onGestureSelect: () -> Void

    @State private var dragStart: CGPoint = .zero
    @State private var baseWidth: CGFloat = 0
    @State private var baseHeight: CGFloat = 0

    var body: some View {
        ZStack {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .grayscale(filterIndex == 1 ? 1.0 : 0.0)
                .colorMultiply(filterIndex == 2 ? Color(red: 1.0, green: 0.9, blue: 0.8) : .white)
                .blur(radius: filterIndex == 3 ? 5.0 : 0.0)
                .frame(
                    width: width,
                    height: shapeIndex == 0 ? height : width
                )
                .clipShape(maskShape())
                .overlay(
                    maskShape().stroke((isSelected && !isPlayMode) ? Color.blue : Color.clear, lineWidth: 2)
                )
                .contentShape(maskShape())
        }
        .gesture(
            TapGesture(count: 2).onEnded { if !isPlayMode { onDoubleTap() } }
            .exclusively(before: TapGesture(count: 1).onEnded { if !isPlayMode { onTapSelect() } })
        )
        .gesture(
            DragGesture(coordinateSpace: .global)
                .onChanged { g in
                    if isPlayMode { return }
                    onGestureSelect()
                    if dragStart == .zero { dragStart = CGPoint(x: x, y: y) }
                    x = min(max(dragStart.x + g.translation.width, 30), canvasSize.width - 30)
                    y = min(max(dragStart.y + g.translation.height, 30), canvasSize.height - 30)
                }
                .onEnded { _ in
                    if isPlayMode { return }
                    dragStart = .zero
                }
        )
        .simultaneousGesture(
            MagnificationGesture()
                .onChanged { scale in
                    if isPlayMode { return }
                    onGestureSelect()
                    if baseWidth == 0 { baseWidth = width; baseHeight = height }
                    width = max(baseWidth * scale, 50)
                    height = max(baseHeight * scale, 50)
                }
                .onEnded { _ in
                    if isPlayMode { return }
                    baseWidth = 0; baseHeight = 0
                }
        )
        .position(x: x, y: y)
    }

    private func maskShape() -> AnyShape {
        switch shapeIndex {
        case 1: return AnyShape(Rectangle())
        case 2: return AnyShape(Circle())
        default: return AnyShape(Rectangle())
        }
    }
}
