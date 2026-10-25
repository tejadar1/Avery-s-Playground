import SwiftUI

enum Activity: String, CaseIterable, Identifiable, Hashable {
    case nails, hair, reading, spanish, abc, counting, colors, animals, drawing, bubbles

    var id: String { rawValue }

    var title: String {
        switch self {
        case .nails: "Nail Salon"
        case .hair: "Hair Salon"
        case .reading: "Read"
        case .spanish: "Español"
        case .abc: "ABC"
        case .counting: "1 2 3"
        case .colors: "Coloring"
        case .animals: "Animals"
        case .drawing: "Draw"
        case .bubbles: "Bubbles"
        }
    }

    /// Drawn in Art/icons/<rawValue>.svg.
    var icon: String { "Icon-\(rawValue)" }

    var color: Color {
        switch self {
        case .nails: .pink
        case .hair: Color(red: 0.85, green: 0.4, blue: 0.9)
        case .reading: .teal
        case .spanish: .mint
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
        case .hair: HairSalonView()
        case .reading: StoriesView()
        case .spanish: SpanishView()
        case .abc: ABCView()
        case .counting: CountingView()
        case .colors: ColorsView()
        case .animals: AnimalsView()
        case .drawing: DrawingView()
        case .bubbles: BubblePopView()
        }
    }
}
