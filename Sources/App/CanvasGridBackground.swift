import SwiftUI

struct CanvasGridBackground: View {
    var body: some View {
        GeometryReader { _ in
            ZStack {
                Color(UIColor.systemBackground)

                // subtle top “fade”
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.03),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .center
                )
                .allowsHitTesting(false)

                DottedGrid()
                    .allowsHitTesting(false)
            }
        }
    }
}

private struct DottedGrid: View {
    // Tune these to match the screenshot
    private let spacing: CGFloat = 26
    private let dotSize: CGFloat = 2.3

    var body: some View {
        Canvas { context, size in
            let cols = Int(size.width / spacing) + 2
            let rows = Int(size.height / spacing) + 2

            for r in 0..<rows {
                for c in 0..<cols {
                    let x = CGFloat(c) * spacing + spacing * 0.5
                    let y = CGFloat(r) * spacing + spacing * 0.5

                    let rect = CGRect(
                        x: x - dotSize / 2,
                        y: y - dotSize / 2,
                        width: dotSize,
                        height: dotSize
                    )

                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(Color.secondary.opacity(0.22))
                    )
                }
            }
        }
    }
}
