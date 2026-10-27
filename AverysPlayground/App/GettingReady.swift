import SwiftUI

/// Picks up where the still launch screen leaves off: the same Coco on the same blue comes to life,
/// gets ready (brush, wash, bow), then hands over to the home screen. A tap skips it.
struct GettingReady: View {
    let done: () -> Void

    private static let steps = ["toothbrush", "soap", "bow"]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var step = 0

    var body: some View {
        ZStack {
            Color("LaunchBackground").ignoresSafeArea()

            // The launch screen's scene, centered the same way, with Coco on top where she was, so nothing jumps
            // (Art/render.js puts her at 30, 50 in a 140-point-wide box).
            Image("LaunchScene")
                .overlay(alignment: .topLeading) { coco.offset(x: 30, y: 50) }
                .overlay(alignment: .bottom) {
                    VStack(spacing: 10) {
                        Text("Getting ready…")
                            .font(.kid(24))
                            .foregroundStyle(Color.outline)
                        HStack(spacing: 12) {
                            ForEach(0..<Self.steps.count, id: \.self) { index in
                                Circle()
                                    .fill(index < step ? Color.white : Color.white.opacity(0.4))
                                    .overlay(Circle().strokeBorder(Color.outline, lineWidth: 3))
                                    .frame(width: 18, height: 18)
                            }
                        }
                    }
                    .fixedSize()
                    .offset(y: 80)
                }
        }
        .ignoresSafeArea()  // the launch screen centers its image on the whole screen, not the safe area
        .contentShape(Rectangle())
        .onTapGesture(perform: done)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Coco is getting ready")
        .accessibilityIdentifier("Getting ready")
        .task {
            for _ in Self.steps {
                try? await Task.sleep(for: .seconds(0.45))
                guard !Task.isCancelled else { return }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { step += 1 }
            }
            try? await Task.sleep(for: .seconds(0.45))
            if !Task.isCancelled { done() }
        }
    }

    private var coco: some View {
        Image("Coco")
            .resizable()
            .frame(width: 140, height: 140 * 440 / 420)
            .phaseAnimator([CGFloat(0), -28, 0], trigger: step) { content, lift in
                content
                    .offset(y: reduceMotion ? 0 : lift)
                    .rotationEffect(.degrees(reduceMotion || lift == 0 ? 0 : (step.isMultiple(of: 2) ? 6 : -6)))
            } animation: { _ in
                .spring(response: 0.22, dampingFraction: 0.55)
            }
            .overlay(alignment: .topTrailing) {
                HStack(spacing: 4) {
                    ForEach(Self.steps.prefix(step), id: \.self) { item in
                        Picture(item, size: 40)
                            .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
                    }
                }
                .offset(x: 70, y: -30)
            }
    }
}

#Preview {
    GettingReady {}
}
