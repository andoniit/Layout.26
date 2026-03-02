import SwiftUI

struct OnboardingView: View {
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            // Background matches the app vibe
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Optional: A little grab handle to indicate it can slide down
                Capsule()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 40, height: 5)
                    .padding(.top, 12)
                
                Spacer()
                
                // MARK: - Header
                VStack(spacing: 12) {
                    Image(systemName: "square.stack.3d.down.forward.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(
                            LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .shadow(color: .blue.opacity(0.3), radius: 15, y: 8)
                    
                    Text("Welcome to Layout.26")
                        .font(.system(size: 28, weight: .bold))
                        .multilineTextAlignment(.center)
                    
                    Text("Your ultimate spatial UI playground. Design, arrange, and interact with native iOS elements instantly.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()

                // MARK: - Features Card
                VStack(spacing: 20) {
                    InfoFeatureRow(icon: "hand.tap.fill", color: .blue, title: "Drag & Drop UI", subtitle: "Add text, images, buttons, and layouts instantly.")
                    InfoFeatureRow(icon: "square.on.circle", color: .purple, title: "Spatial Glass", subtitle: "Morph shapes and apply ultra-thin refractive effects.")
                    InfoFeatureRow(icon: "play.fill", color: .green, title: "Interactive Play", subtitle: "Test designs live. Buttons squish and toggles switch.")
                    InfoFeatureRow(icon: "square.3.layers.3d", color: .orange, title: "Advanced Layers", subtitle: "Bring forward, send backward, and fine-tune.")
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                        .shadow(color: .black.opacity(0.05), radius: 20, y: 10)
                )
                .padding(.horizontal, 20)

                Spacer()

                // MARK: - Footer Button & Credits
                VStack(spacing: 16) {
                    Button(action: onContinue) {
                        Text("Start Designing")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .shadow(color: .blue.opacity(0.3), radius: 10, y: 5)
                    }
                    .padding(.horizontal, 20)
                    
                    // 👈 Your Developer Credit!
                    Text("Designed and developed by Anirudha Kapileshwari")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .padding(.bottom, 10)
                }
            }
        }
    }
}

// MARK: - Reusable Row Component
struct InfoFeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(color.opacity(0.15))
                    .frame(width: 46, height: 46)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
