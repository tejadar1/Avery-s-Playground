import SwiftUI

enum Activity: String, CaseIterable, Identifiable, Hashable {
    case nails, hair, pet, reading, spanish, abc, counting, colors, animals, drawing, bubbles

    var id: String { rawValue }

    var title: String {
        switch self {
        case .nails: "Nail Salon"
        case .hair: "Hair Salon"
        case .pet: "Mochi"
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
        case .nails: Color(red: 0.95, green: 0.47, blue: 0.6)
        case .hair: Color(red: 0.78, green: 0.5, blue: 0.86)
        case .pet: Color(red: 0.72, green: 0.52, blue: 0.42)
        case .reading: Color(red: 0.31, green: 0.67, blue: 0.75)
        case .spanish: Color(red: 0.36, green: 0.75, blue: 0.68)
        case .abc: Color(red: 0.9, green: 0.42, blue: 0.38)
        case .counting: Color(red: 0.95, green: 0.62, blue: 0.3)
        case .colors: Color(red: 0.66, green: 0.5, blue: 0.85)
        case .animals: Color(red: 0.45, green: 0.72, blue: 0.42)
        case .drawing: Color(red: 0.33, green: 0.56, blue: 0.86)
        case .bubbles: Color(red: 0.4, green: 0.75, blue: 0.9)
        }
    }

    @ViewBuilder
    var destination: some View {
        switch self {
        case .nails: NailSalonView()
        case .hair: HairSalonView()
        case .pet: PetView()
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
