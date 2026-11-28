import SwiftUI

enum Activity: String, CaseIterable, Identifiable, Hashable {
    case nails, hair, dressup, dentist, pet, hop, maze, spot, bake, piano, reading, rhyme, patterns, sorting, feelings, math, spanish, abc, tracing, spelling, counting, sounds, clap, colors, drawing, bingo, race, fruit, tictactoe, memory, hide, ispy, fishing, puzzle, routines, chores, busy, blocks, garden, readalong, carwash, dinodig, scale, sinkfloat, code, tower, lifecycle, ramp, positions

    var id: String { rawValue }

    var title: String {
        switch self {
        case .nails: "Nail Salon"
        case .hair: "Hair Salon"
        case .dressup: "Dress Up"
        case .dentist: "Dentist"
        case .pet: "Mochi"
        case .hop: "Coco Hop"
        case .maze: "Maze"
        case .spot: "Find It"
        case .piano: "Piano"
        case .reading: "Stories"
        case .rhyme: "Rhyme Time"
        case .patterns: "What's Next?"
        case .sorting: "Sort It"
        case .feelings: "Feelings"
        case .math: "Math"
        case .spanish: "Español"
        case .abc: "ABC"
        case .tracing: "Trace"
        case .spelling: "Spell"
        case .counting: "1 2 3"
        case .sounds: "Sound Spy"
        case .clap: "Clap It"
        case .fruit: "Fruit Picking"
        case .colors: "Coloring"
        case .drawing: "Draw"
        case .bingo: "Bingo"
        case .tictactoe: "Tic-Tac-Toe"
        case .memory: "Memory"
        case .race: "Number Race"
        case .hide: "Hide Coco"
        case .ispy: "I Spy"
        case .puzzle: "Puzzles"
        case .bake: "Bake Shop"
        case .fishing: "Go Fishing"
        case .routines: "Day & Night"
        case .chores: "Helper"
        case .busy: "Busy Board"
        case .blocks: "Blocks"
        case .garden: "Garden"
        case .readalong: "Read"
        case .carwash: "Car Wash"
        case .dinodig: "Dino Dig"
        case .scale: "Balance Scale"
        case .sinkfloat: "Sink or Float"
        case .code: "Coco Code"
        case .tower: "Big to Small"
        case .lifecycle: "Life Cycles"
        case .ramp: "Ramps"
        case .positions: "In, On, Under"
        }
    }

    var section: HomeSection {
        switch self {
        case .reading, .readalong, .rhyme, .patterns, .sorting, .feelings, .abc, .tracing, .spelling, .counting, .sounds, .clap, .math, .spanish, .piano: .learn
        case .nails, .hair, .dressup, .dentist, .pet, .hop, .maze, .spot, .bake, .puzzle, .colors, .drawing, .carwash, .dinodig: .play
        case .bingo, .race, .fruit, .tictactoe, .memory, .hide, .ispy, .fishing: .teamUp
        case .routines, .chores: .myDay
        case .busy, .blocks, .garden: .calm
        case .scale, .sinkfloat, .code, .tower, .lifecycle, .ramp, .positions: .discover
        }
    }

    /// The background tune. The piano makes its own music, games about hearing words and letter sounds stay quiet,
    /// and so do the calm toys.
    var tune: Tune? {
        switch self {
        case .piano, .spelling, .reading, .readalong, .rhyme, .sounds, .clap, .abc, .busy, .blocks, .garden: nil
        case .nails, .hair, .dressup, .dentist, .bake: .salon
        case .pet, .hop, .maze, .spot, .puzzle, .carwash, .dinodig: .pet
        case .colors, .drawing: .art
        case .bingo, .race, .fruit, .tictactoe, .memory, .hide, .ispy, .fishing, .routines, .chores: .teamUp
        case .patterns, .sorting, .feelings, .math, .spanish, .tracing, .counting: .learn
        case .scale, .sinkfloat, .code, .tower, .lifecycle, .ramp, .positions: .learn
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
        case .hop: Color(red: 0.55, green: 0.36, blue: 0.85)
        case .maze: Color(red: 0.38, green: 0.72, blue: 0.4)
        case .spot: Color(red: 0.95, green: 0.55, blue: 0.4)
        case .piano: Color(red: 0.42, green: 0.5, blue: 0.85)
        case .reading: Color(red: 0.31, green: 0.67, blue: 0.75)
        case .rhyme: Color(red: 0.93, green: 0.45, blue: 0.6)
        case .patterns: Color(red: 0.62, green: 0.55, blue: 0.9)
        case .sorting: Color(red: 0.45, green: 0.72, blue: 0.42)
        case .feelings: Color(red: 0.95, green: 0.62, blue: 0.3)
        case .math: Color(red: 0.9, green: 0.72, blue: 0.3)
        case .spanish: Color(red: 0.36, green: 0.75, blue: 0.68)
        case .abc: Color(red: 0.9, green: 0.42, blue: 0.38)
        case .tracing: Color(red: 0.36, green: 0.61, blue: 0.84)
        case .spelling: Color(red: 0.95, green: 0.55, blue: 0.4)
        case .counting: Color(red: 0.95, green: 0.62, blue: 0.3)
        case .sounds: Color(red: 0.95, green: 0.39, blue: 0.37)
        case .clap: Color(red: 0.62, green: 0.45, blue: 0.9)
        case .fruit: Color(red: 0.45, green: 0.72, blue: 0.42)
        case .colors: Color(red: 0.66, green: 0.5, blue: 0.85)
        case .drawing: Color(red: 0.33, green: 0.56, blue: 0.86)
        case .bingo: Color(red: 0.4, green: 0.75, blue: 0.9)
        case .tictactoe: Color(red: 0.62, green: 0.55, blue: 0.9)
        case .memory: Color(red: 0.36, green: 0.75, blue: 0.68)
        case .race: Color(red: 0.98, green: 0.72, blue: 0.3)
        case .hide: Color(red: 0.88, green: 0.62, blue: 0.36)
        case .ispy: Color(red: 0.4, green: 0.72, blue: 0.9)
        case .puzzle: Color(red: 0.78, green: 0.5, blue: 0.86)
        case .bake: Color(red: 0.95, green: 0.55, blue: 0.65)
        case .fishing: Color(red: 0.36, green: 0.66, blue: 0.88)
        case .routines: Color(red: 0.42, green: 0.5, blue: 0.85)
        case .chores: Color(red: 0.45, green: 0.72, blue: 0.42)
        case .busy: Color(red: 0.95, green: 0.62, blue: 0.3)
        case .blocks: Color(red: 0.36, green: 0.61, blue: 0.84)
        case .garden: Color(red: 0.45, green: 0.72, blue: 0.42)
        case .readalong: Color(red: 0.36, green: 0.4, blue: 0.75)
        case .carwash: Color(red: 0.36, green: 0.66, blue: 0.88)
        case .dinodig: Color(red: 0.91, green: 0.63, blue: 0.31)
        case .scale: Color(red: 0.91, green: 0.63, blue: 0.31)
        case .sinkfloat: Color(red: 0.36, green: 0.66, blue: 0.88)
        case .code: Color(red: 0.36, green: 0.4, blue: 0.75)
        case .tower: Color(red: 0.56, green: 0.48, blue: 0.82)
        case .lifecycle: Color(red: 0.43, green: 0.71, blue: 0.35)
        case .ramp: Color(red: 0.85, green: 0.57, blue: 0.35)
        case .positions: Color(red: 0.6, green: 0.48, blue: 0.82)
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
        case .hop: HopView()
        case .maze: MazeView()
        case .spot: SpotView()
        case .piano: PianoView()
        case .reading: StoriesView()
        case .rhyme: RhymeView()
        case .patterns: PatternView()
        case .sorting: SortView()
        case .feelings: FeelingsView()
        case .math: MathView()
        case .spanish: SpanishView()
        case .abc: ABCView()
        case .tracing: TracingView()
        case .spelling: SpellView()
        case .counting: CountingView()
        case .sounds: SoundSpyView()
        case .clap: ClapView()
        case .fruit: FruitView()
        case .colors: ColorsView()
        case .drawing: DrawingView()
        case .bingo: BingoView()
        case .tictactoe: TicTacToeView()
        case .memory: MemoryView()
        case .race: NumberRaceView()
        case .hide: HideView()
        case .ispy: ISpyView()
        case .puzzle: PuzzleView()
        case .bake: BakeView()
        case .fishing: FishingView()
        case .routines: RoutinesView()
        case .chores: RoutinesView(kinds: [.chores])
        case .busy: BusyBoardView()
        case .blocks: BlocksView()
        case .garden: GardenView()
        case .readalong: ReadAlongView()
        case .carwash: CarWashView()
        case .dinodig: DinoDigView()
        case .scale: ScaleView()
        case .sinkfloat: SinkFloatView()
        case .code: CodeView()
        case .tower: TowerView()
        case .lifecycle: LifeCycleView()
        case .ramp: RampView()
        case .positions: PositionsView()
        }
    }
}

/// The choices on the home screen; each opens a page of its games.
enum HomeSection: String, CaseIterable, Identifiable, Hashable {
    case learn, discover, play, teamUp, myDay, calm

    var id: String { rawValue }

    var title: String {
        switch self {
        case .learn: "Learn"
        case .discover: "Discover"
        case .play: "Play"
        case .teamUp: "Team Up"
        case .myDay: "My Day"
        case .calm: "Calm"
        }
    }

    var subtitle: String {
        switch self {
        case .learn: "Letters, words, numbers and music"
        case .discover: "Science, building and coding"
        case .play: "Pretend, dress up and make art"
        case .teamUp: "Play with your grown-up"
        case .myDay: "Morning, bedtime and helping out"
        case .calm: "Quiet toys, nothing to win"
        }
    }

    var color: Color {
        switch self {
        case .learn: Color(red: 0.31, green: 0.67, blue: 0.75)
        case .discover: Color(red: 0.43, green: 0.71, blue: 0.35)
        case .play: Color(red: 0.95, green: 0.47, blue: 0.6)
        case .teamUp: Color(red: 0.95, green: 0.62, blue: 0.3)
        case .myDay: Color(red: 0.42, green: 0.55, blue: 0.88)
        case .calm: Color(red: 0.36, green: 0.72, blue: 0.66)
        }
    }

    var activities: [Activity] { Activity.allCases.filter { $0.section == self } }
}
