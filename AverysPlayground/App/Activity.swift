import SwiftUI

enum Activity: String, CaseIterable, Identifiable, Hashable {
    case nails, reading, abc, counting, colors, animals, drawing, bubbles

    var id: String { rawValue }

    var title: String {
        switch self {
        case .nails: "Nail Salon"
        case .reading: "Read"
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
        case .nails: "💅"
        case .reading: "📖"
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
        case .nails: .pink
        case .reading: .teal
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
        case .nails: NailSalonView()
        case .reading: ReadingView()
        case .abc: ABCView()
        case .counting: CountingView()
        case .colors: ColorsView()
        case .animals: AnimalsView()
        case .drawing: DrawingView()
        case .bubbles: BubblePopView()
        }
    }
}
