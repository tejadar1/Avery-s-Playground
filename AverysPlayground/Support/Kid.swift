import SwiftUI

/// The child's name, typed in by a grown-up the first time the app opens, and used wherever the app talks to her:
/// the home screen, tracing her name, the photos, the salon friends, bedtime and Español.
enum Kid {
    static let key = "kidName"

    /// Her name, or Avery until a grown-up has typed one.
    static var name: String { saved.isEmpty ? "Avery" : saved }
    static var saved: String { UserDefaults.standard.string(forKey: key)?.trimmingCharacters(in: .whitespaces) ?? "" }

    /// The letters of her name to trace: A to Z only (accents dropped), at most 10.
    static func letters(of name: String = name) -> String {
        String(name.folding(options: .diacriticInsensitive, locale: nil).uppercased().filter { ("A"..."Z").contains($0) }.prefix(10))
    }

    /// Lines with her name are recorded for Avery. For any other name, Coco says the same line without it:
    /// "Hi Liam!" is "Hi!", "Liam! You wrote your name!" is "You wrote your name!", "Sweet dreams, Liam!" is "Sweet dreams!".
    /// Nil when there's no name in the line to leave out.
    static func unnamed(_ line: String, name: String = name) -> String? {
        guard name != "Avery", line.contains(name) else { return nil }
        let out = line.replacingOccurrences(of: "Hi \(name)!", with: "Hi!")
            .replacingOccurrences(of: ", \(name)!", with: "!")
            .replacingOccurrences(of: "\(name)! ", with: "")
        return out == line ? nil : out
    }
}

/// Asks a grown-up for the child's name: the first time the app opens, and from the pencil on the home screen.
struct NameEntry: View {
    @AppStorage(Kid.key) private var saved = ""
    @State private var name = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 22 * uiScale) {
            CocoFigure(height: 120 * uiScale)
            Text("Hi! What's your child's name?")
                .font(.kid(30))
                .foregroundStyle(Color.outline)
                .multilineTextAlignment(.center)
            Text("Coco will use it in the games, and it's what they'll trace in Trace.")
                .font(.kid(18))
                .foregroundStyle(Color.outline.opacity(0.7))
                .multilineTextAlignment(.center)
            TextField("Name", text: $name)
                .font(.kid(30))
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .onSubmit(save)
                .padding(.vertical, 14 * uiScale)
                .background(.white, in: RoundedRectangle(cornerRadius: 20 * uiScale, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 20 * uiScale, style: .continuous).strokeBorder(Color.outline, lineWidth: 2.5 * uiScale))
                .frame(maxWidth: 420 * uiScale)
                .accessibilityIdentifier("Name")
            Button(action: save) {
                Text("Let's play!")
                    .font(.kid(28))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 34 * uiScale)
                    .frame(height: 64 * uiScale)
                    .cartoonCard(Color(red: 0.45, green: 0.72, blue: 0.42), cornerRadius: 32 * uiScale)
            }
            .buttonStyle(SquishyButtonStyle())
            .disabled(Kid.letters(of: name).isEmpty)
            .opacity(Kid.letters(of: name).isEmpty ? 0.5 : 1)
        }
        .padding(30 * uiScale)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PlayfulBackground())
        .interactiveDismissDisabled(saved.isEmpty)  // the first time, a name is needed to start
        .onAppear { name = saved }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !Kid.letters(of: trimmed).isEmpty else { return }
        saved = trimmed
        Haptics.tap()
        dismiss()
    }
}
