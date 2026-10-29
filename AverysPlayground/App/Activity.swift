import SwiftUI

enum Activity: String, CaseIterable, Identifiable, Hashable {
    case nails, hair, dressup, dentist, pet, maze, spot, piano, reading, math, spanish, abc, tracing, spelling, counting, colors, drawing, bingo, tictactoe, memory, routines

    var id: String { rawValue }

    var title: String {
        switch self {
        case .nails: "Nail Salon"
        case .hair: "Hair Salon"
        case .dressup: "Dress Up"
        case .dentist: "Dentist"
        case .pet: "Mochi"
        case .maze: "Maze"
        case .spot: "Spot It"
        case .piano: "Piano"
        case .reading: "Read"
        case .math: "Math"
        case .spanish: "Español"
        case .abc: "ABC"
        case .tracing: "Trace"
        case .spelling: "Spell"
        case .counting: "1 2 3"
        case .colors: "Coloring"
        case .drawing: "Draw"
        case .bingo: "Bingo"
        case .tictactoe: "Tic-Tac-Toe"
        case .memory: "Memory"
        case .routines: "Routines"
        }
    }

    var section: HomeSection {
        switch self {
        case .reading, .abc, .tracing, .spelling, .counting, .math, .spanish, .piano: .learn
        case .nails, .hair, .dressup, .dentist, .pet, .maze, .spot, .colors, .drawing: .play
        case .bingo, .tictactoe, .memory, .routines: .teamUp
        }
    }

    /// The background tune; the piano makes its own music, so it has none.
    var tune: Tune? {
        switch self {
        case .piano: nil
        case .nails, .hair, .dressup, .dentist: .salon
        case .pet, .maze, .spot: .pet
        case .colors, .drawing: .art
        case .bingo, .tictactoe, .memory, .routines: .teamUp
        case .reading, .math, .spanish, .abc, .tracing, .spelling, .counting: .learn
        }
    }

    /// Drawn in Art/icons/<rawValue>.svg.
    var icon: String { "Icon-\(rawValue)" }

    var color: Color {
        switch self {
        case .nails: Color(red: 0.95, green: 0.47, blue: 0.6)
        case .hair: Color(red: 0.78, green: 0.5, blue: 0.86)
        case .dressup: Color(red: 0.92, green: 0.55, blue: 0.75)
        case .dentist: Color(red: 0.4, green: 0.72, blue: 0.9)
        case .pet: Color(red: 0.72, green: 0.52, blue: 0.42)
        case .maze: Color(red: 0.38, green: 0.72, blue: 0.4)
        case .spot: Color(red: 0.95, green: 0.55, blue: 0.4)
        case .piano: Color(red: 0.42, green: 0.5, blue: 0.85)
        case .reading: Color(red: 0.31, green: 0.67, blue: 0.75)
        case .math: Color(red: 0.9, green: 0.72, blue: 0.3)
        case .spanish: Color(red: 0.36, green: 0.75, blue: 0.68)
        case .abc: Color(red: 0.9, green: 0.42, blue: 0.38)
        case .tracing: Color(red: 0.36, green: 0.61, blue: 0.84)
        case .spelling: Color(red: 0.95, green: 0.55, blue: 0.4)
        case .counting: Color(red: 0.95, green: 0.62, blue: 0.3)
        case .colors: Color(red: 0.66, green: 0.5, blue: 0.85)
        case .drawing: Color(red: 0.33, green: 0.56, blue: 0.86)
        case .bingo: Color(red: 0.4, green: 0.75, blue: 0.9)
        case .tictactoe: Color(red: 0.62, green: 0.55, blue: 0.9)
        case .memory: Color(red: 0.36, green: 0.75, blue: 0.68)
        case .routines: Color(red: 0.42, green: 0.5, blue: 0.85)
        }
    }

    @ViewBuilder
    var destination: some View {
        switch self {
        case .nails: NailSalonView()
        case .hair: HairSalonView()
        case .dressup: DressUpView()
        case .dentist: DentistView()
        case .pet: PetView()
        case .maze: MazeView()
        case .spot: SpotView()
        case .piano: PianoView()
        case .reading: StoriesView()
        case .math: MathView()
        case .spanish: SpanishView()
        case .abc: ABCView()
        case .tracing: TracingView()
        case .spelling: SpellView()
        case .counting: CountingView()
        case .colors: ColorsView()
        case .drawing: DrawingView()
        case .bingo: BingoView()
        case .tictactoe: TicTacToeView()
        case .memory: MemoryView()
        case .routines: RoutinesView()
        }
    }
}

/// The three choices on the home screen; each opens a page of its games.
enum HomeSection: String, CaseIterable, Identifiable, Hashable {
    case learn, play, teamUp

    var id: String { rawValue }

    var title: String {
        switch self {
        case .learn: "Learn"
        case .play: "Play"
        case .teamUp: "Team Up"
        }
    }

    var subtitle: String {
        switch self {
        case .learn: "Letters, words, numbers and music"
        case .play: "Pretend, dress up and make art"
        case .teamUp: "Play with your grown-up"
        }
    }

    var color: Color {
        switch self {
        case .learn: Color(red: 0.31, green: 0.67, blue: 0.75)
        case .play: Color(red: 0.95, green: 0.47, blue: 0.6)
        case .teamUp: Color(red: 0.95, green: 0.62, blue: 0.3)
        }
    }

    var activities: [Activity] { Activity.allCases.filter { $0.section == self } }
}
