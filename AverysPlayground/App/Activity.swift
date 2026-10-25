import SwiftUI

enum Activity: String, CaseIterable, Identifiable, Hashable {
    case abc, counting, colors, animals, drawing, bubbles

    var id: String { rawValue }

    var title: String {
        switch self {
        case .abc: "ABC"
        case .counting: "1 2 3"
        case .colors: "Colors"
        case .animals: "Animals"
        case .drawing: "Draw"
        case .bubbles: "Bubbles"
        }
    }

    var emoji: String {
        switch self {
        case .abc: "🔤"
        case .counting: "🔢"
        case .colors: "🎨"
        case .animals: "🐮"
        case .drawing: "🖍️"
        case .bubbles: "🫧"
        }
    }

    var color: Color {
        switch self {
        case .abc: .red
        case .counting: .orange
        case .colors: .purple
        case .animals: .green
        case .drawing: .blue
        case .bubbles: .cyan
        }
    }

    @ViewBuilder
    var destination: some View {
        switch self {
        case .abc: ABCView()
        case .counting: CountingView()
        case .colors: ColorsView()
        case .animals: AnimalsView()
        case .drawing: DrawingView()
        case .bubbles: BubblePopView()
        }
    }
}
