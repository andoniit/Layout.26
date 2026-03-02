import SwiftUI

struct TextElement: View {
    let id: UUID

    @Binding var text: String
    @Binding var x: CGFloat
    @Binding var y: CGFloat
    @Binding var width: CGFloat
    @Binding var fontSize: CGFloat
    @Binding var isBold: Bool
    @Binding var isItalic: Bool
    @Binding var designIndex: Int
    @Binding var color: Color

    let canvasSize: CGSize
    let isSelected: Bool
    var isPlayMode: Bool
    let onTapSelect: () -> Void
    let onDoubleTap: () -> Void
    let onGestureSelect: () -> Void
    let onTapOutside: () -> Void

    // Drag move
    @State private var dragStart: CGPoint = .zero

    // Pinch
    @State private var baseFont: CGFloat = 0
    @State private var baseWidth: CGFloat = 0

    private let blue = Color.blue

    var body: some View {
        ZStack {
            Group {
                if isItalic {
                    Text(text)
                        .font(font())
                        .italic()
                        .foregroundStyle(color)
                        .frame(width: width, alignment: .leading)
                } else {
                    Text(text)
                        .font(font())
                        .foregroundStyle(color)
                        .frame(width: width, alignment: .leading)
                }
            }
            .padding(.horizontal, 0)
            .padding(.vertical, 0)
            .overlay {
                if isSelected && !isPlayMode {
                    Rectangle().stroke(blue, lineWidth: 2)
                }
            }
        }
        .contentShape(Rectangle())
        .gesture(
            TapGesture(count: 2).onEnded {
                if !isPlayMode {
                    onDoubleTap()
                }
            }
            .exclusively(before:
                TapGesture(count: 1).onEnded {
                    if !isPlayMode {
                        onTapSelect()
                    }
                }
            )
        )
        // Move
        .gesture(
            DragGesture(coordinateSpace: .global)
                .onChanged { g in
                    if isPlayMode { return }
                    onGestureSelect()
                    if dragStart == .zero { dragStart = CGPoint(x: x, y: y) }
                    x = clamp(dragStart.x + g.translation.width, 30, canvasSize.width - 30)
                    y = clamp(dragStart.y + g.translation.height, 30, canvasSize.height - 30)
                }
                .onEnded { _ in
                    if isPlayMode { return }
                    dragStart = .zero
                }
        )
        // Pinch to resize
        .simultaneousGesture(
            MagnificationGesture()
                .onChanged { scale in
                    if isPlayMode { return }
                    onGestureSelect()
                    if baseFont == 0 { baseFont = fontSize }
                    if baseWidth == 0 { baseWidth = width }
                    fontSize = clamp(baseFont * scale, 14, 160)
                    width = clamp(baseWidth * scale, 120, canvasSize.width - 40)
                }
                .onEnded { _ in
                    if isPlayMode { return }
                    baseFont = 0
                    baseWidth = 0
                }
        )
        .position(x: x, y: y)
    }

    private func font() -> Font {
        let design: Font.Design
        switch designIndex {
        case 1: design = .rounded
        case 2: design = .serif
        case 3: design = .monospaced
        default: design = .default
        }
        let weight: Font.Weight = isBold ? .bold : .regular
        return .system(size: fontSize, weight: weight, design: design)
    }

    private func clamp(_ v: CGFloat, _ minV: CGFloat, _ maxV: CGFloat) -> CGFloat {
        Swift.max(minV, Swift.min(maxV, v))
    }
}

