import SwiftUI

struct TopNavBar: View {
    @Binding var isPlayMode: Bool
    @Binding var canvasBackgroundColor: Color
    let canUndo: Bool
    let onUndo: () -> Void
    let onRedo: () -> Void

    @AppStorage("appearanceMode_v2") private var appearanceModeRaw: String = RootView.AppearanceMode.system.rawValue

    var body: some View {
        HStack(spacing: 16) {
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    isPlayMode.toggle()
                }
            }) {
                Image(systemName: isPlayMode ? "stop.fill" : "play.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(isPlayMode ? .red : .primary)
                    .frame(width: 44, height: 44)
                    .background(isPlayMode ? Color.red.opacity(0.15) : Color(UIColor.tertiarySystemFill))
                    .clipShape(Circle())
            }

            Spacer()

            if !isPlayMode {
                HStack(spacing: 12) {
                    Button(action: onUndo) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 18, weight: .semibold))
                            .frame(width: 40, height: 40)
                            .background(Color(UIColor.tertiarySystemFill))
                            .clipShape(Circle())
                    }
                    .disabled(!canUndo)
                    .opacity(canUndo ? 1.0 : 0.4)

                    Button(action: onRedo) {
                        Image(systemName: "arrow.uturn.forward")
                            .font(.system(size: 18, weight: .semibold))
                            .frame(width: 40, height: 40)
                            .background(Color(UIColor.tertiarySystemFill))
                            .clipShape(Circle())
                    }
                    .disabled(true)
                    .opacity(0.4)
                }

                ColorPicker("", selection: $canvasBackgroundColor)
                    .labelsHidden()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }
}
