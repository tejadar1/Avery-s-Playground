import SwiftUI

enum Activity: String, CaseIterable, Identifiable, Hashable {
    case nails, hair, dressup, pet, piano, reading, math, spanish, abc, counting, colors, drawing, bubbles

    var id: String { rawValue }

    var title: String {
        switch self {
        case .nails: "Nail Salon"
        case .hair: "Hair Salon"
        case .dressup: "Dress Up"
        case .pet: "Mochi"
        case .piano: "Piano"
        case .reading: "Read"
        case .math: "Math"
        case .spanish: "Español"
        case .abc: "ABC"
        case .counting: "1 2 3"
        case .colors: "Coloring"
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
        case .dressup: Color(red: 0.92, green: 0.55, blue: 0.75)
        case .pet: Color(red: 0.72, green: 0.52, blue: 0.42)
        case .piano: Color(red: 0.42, green: 0.5, blue: 0.85)
        case .reading: Color(red: 0.31, green: 0.67, blue: 0.75)
        case .math: Color(red: 0.9, green: 0.72, blue: 0.3)
        case .spanish: Color(red: 0.36, green: 0.75, blue: 0.68)
        case .abc: Color(red: 0.9, green: 0.42, blue: 0.38)
        case .counting: Color(red: 0.95, green: 0.62, blue: 0.3)
        case .colors: Color(red: 0.66, green: 0.5, blue: 0.85)
        case .drawing: Color(red: 0.33, green: 0.56, blue: 0.86)
        case .bubbles: Color(red: 0.4, green: 0.75, blue: 0.9)
        }
    }

    @ViewBuilder
    var destination: some View {
        switch self {
        case .nails: NailSalonView()
        case .hair: HairSalonView()
        case .dressup: DressUpView()
        case .pet: PetView()
        case .piano: PianoView()
        case .reading: StoriesView()
        case .math: MathView()
        case .spanish: SpanishView()
        case .abc: ABCView()
        case .counting: CountingView()
        case .colors: ColorsView()
        case .drawing: DrawingView()
        case .bubbles: BubblePopView()
        }
    }
}
