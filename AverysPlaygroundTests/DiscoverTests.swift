import XCTest
@testable import AverysPlayground

final class DiscoverTests: XCTestCase {
    func testTheScaleTipsTowardTheHeavierSide() {
        let mouse = Balance.things.first { $0.picture == "mouse" }!, elephant = Balance.things.first { $0.picture == "elephant" }!
        XCTAssertEqual(Balance.tilt(left: [], right: []), 0, "empty: level")
        XCTAssertEqual(Balance.tilt(left: [mouse], right: [mouse]), 0, "the same weight balances")
        XCTAssertGreaterThan(Balance.tilt(left: [mouse], right: [elephant]), 0, "down on the right")
        XCTAssertLessThan(Balance.tilt(left: [elephant], right: [mouse]), 0, "down on the left")
        XCTAssertEqual(abs(Balance.tilt(left: [], right: [mouse])), 16, "against an empty pan it tips all the way")
        for thing in Balance.things { XCTAssertNotNil(UIImage(named: "Picture-" + thing.picture), thing.picture) }
    }

    func testSinkOrFloatHasBothKindsWithPictures() {
        XCTAssertTrue(SinkFloat.things.contains { $0.floats })
        XCTAssertTrue(SinkFloat.things.contains { !$0.floats })
        for thing in SinkFloat.things { XCTAssertNotNil(UIImage(named: "Picture-" + thing.picture), thing.picture) }
    }

    func testCocoWalksHerArrowsAndStopsAtRocksAndEdges() {
        let level = Code.Level(start: Code.Cell(x: 0, y: 1), goal: Code.Cell(x: 3, y: 1), rocks: [Code.Cell(x: 2, y: 1)])
        XCTAssertEqual(level.run([.right, .right]).outcome, .bonk, "a rock in the way")
        XCTAssertEqual(level.run([.right, .right]).path, [Code.Cell(x: 1, y: 1)], "she stops before the rock")
        XCTAssertEqual(level.run([.up, .up]).outcome, .bonk, "off the top edge")
        XCTAssertEqual(level.run([.right]).outcome, .short)
        XCTAssertEqual(level.run([.right, .down, .right, .right, .up]).outcome, .snack, "around the rock")
        XCTAssertEqual(level.run([.right, .down, .right, .right, .up, .up]).path.last, level.goal, "she stops at her snack")
    }

    func testEveryCodeLevelCanBeSolved() {
        for (index, level) in Code.levels.enumerated() {
            // Shortest way there, square by square, avoiding rocks
            var paths: [Code.Cell: [Code.Step]] = [level.start: []], queue = [level.start]
            while !queue.isEmpty {
                let at = queue.removeFirst()
                for step in Code.Step.allCases {
                    let next = Code.Cell(x: at.x + step.move.dx, y: at.y + step.move.dy)
                    guard paths[next] == nil, (0..<Code.Level.columns).contains(next.x), (0..<Code.Level.rows).contains(next.y),
                          !level.rocks.contains(next) else { continue }
                    paths[next] = paths[at]! + [step]
                    queue.append(next)
                }
            }
            let program = paths[level.goal]
            XCTAssertNotNil(program, "level \(index + 1) has a way through")
            XCTAssertEqual(level.run(program ?? []).outcome, .snack, "level \(index + 1)")
            XCTAssertLessThanOrEqual(program?.count ?? 0, 12, "level \(index + 1) fits in the plan")
        }
    }

    func testTheTowerGoesBiggestFirst() {
        XCTAssertEqual(Tower.next(placed: 0), 0)
        XCTAssertEqual(Tower.next(placed: 3), 3)
        XCTAssertNil(Tower.next(placed: Tower.count), "built")
        XCTAssertGreaterThan(Tower.size(0), Tower.size(Tower.count - 1))
    }

    func testEveryLifeCycleStageHasAPicture() {
        for cycle in LifeCycle.all {
            XCTAssertGreaterThanOrEqual(cycle.stages.count, 3)
            for stage in cycle.stages { XCTAssertNotNil(UIImage(named: "Picture-" + stage.picture), stage.picture) }
        }
    }

    func testRampFloorNumbersCountFromTheEndOfTheRamp() {
        XCTAssertEqual(Ramp.mark(at: 50, rampEnd: 100, width: 700), 0, "still on the ramp")
        XCTAssertEqual(Ramp.mark(at: 120, rampEnd: 100, width: 700), 1)
        XCTAssertEqual(Ramp.mark(at: 699, rampEnd: 100, width: 700), Ramp.marks)
        XCTAssertEqual(Ramp.mark(at: 900, rampEnd: 100, width: 700), Ramp.marks, "never past the last number")
        for thing in Ramp.Thing.allCases { XCTAssertNotNil(UIImage(named: "Picture-" + thing.rawValue), thing.rawValue) }
    }

    @MainActor
    func testARampThingIsASolidThingThatRolls() {
        let scene = RampScene()
        scene.lay(size: CGSize(width: 800, height: 500), height: .high)
        let before = scene.children.count
        scene.release(.ball)
        XCTAssertEqual(scene.children.count, before + 1)
        XCTAssertEqual(scene.children.last?.physicsBody?.isDynamic, true)
        scene.release(.box)
        XCTAssertEqual(scene.children.count, before + 1, "the last one is taken away")
    }

    func testEachPlaceIsFoundWhereItsToysRest() {
        for place in Positions.Place.allCases {
            XCTAssertEqual(Positions.place(at: place.spot), place, place.words)
        }
        XCTAssertNil(Positions.place(at: CGPoint(x: 0.5, y: 0.02)), "up in the air")
        for toy in Positions.toys { XCTAssertNotNil(UIImage(named: "Picture-" + toy), toy) }
    }
}
