import UIKit
import XCTest
@testable import AverysPlayground

/// What's Next?, Sort It and Feelings.
final class LearnGamesTests: XCTestCase {
    func testPatternAnswerContinuesTheRow() {
        for stars in [0, 5, 10] {
            for _ in 0..<200 {
                let round = PatternRound.random(stars: stars)
                let units = PatternRound.units(stars: stars)
                // Some unit repeats along the row and gives the answer next.
                XCTAssertTrue(units.contains { unit in
                    let picked = round.shown.prefix(unit.count)
                    guard Set(unit).count == Set(picked.map(\.text)).count else { return false }
                    let rule = unit.map { round.shown[unit.firstIndex(of: $0)!] }
                    return (round.shown + [round.answer]).enumerated().allSatisfy { $0.element == rule[$0.offset % unit.count] }
                }, "\(round.shown.map(\.text)) then \(round.answer.text)")
                XCTAssertTrue(round.choices.contains(round.answer))
                XCTAssertEqual(Set(round.choices.map(\.text)).count, 3)
            }
        }
        XCTAssertEqual(PatternRound.units(stars: 0), [[0, 1]], "starts with the easiest pattern")
    }

    func testSortingBasketsDontOverlap() {
        for sorting in Sorting.all {
            XCTAssertTrue(Set(sorting.left.things.map(\.text)).isDisjoint(with: sorting.right.things.map(\.text)), sorting.question)
            let pile = sorting.pile()
            XCTAssertEqual(pile.filter(sorting.left.things.contains).count, 3)
            XCTAssertEqual(pile.filter(sorting.right.things.contains).count, 3)
        }
    }

    func testFeelingsRoundsHaveThreeClearlyDifferentFaces() {
        for moment in [false, true] {
            for _ in 0..<200 {
                let round = FeelingsRound.random(moment: moment, after: Feeling.all[0])
                XCTAssertNotEqual(round.answer, Feeling.all[0], "not the same feeling twice in a row")
                XCTAssertEqual(Set(round.choices.map(\.group)).count, 3, "no look-alike faces together")
                XCTAssertTrue(round.choices.contains(round.answer))
                XCTAssertEqual(round.moment != nil, moment)
                if let picked = round.moment { XCTAssertEqual(picked.feeling, round.answer.name) }
            }
        }
        for moment in FeelingMoment.all {
            XCTAssertTrue(Feeling.all.contains { $0.name == moment.feeling }, moment.text)
        }
    }

    func testEveryPictureExists() {
        let pictures = PatternRound.things.map(\.picture)
            + Sorting.all.flatMap { [$0.left, $0.right] }.flatMap { [$0.picture] + $0.things.map(\.picture) }
            + Feeling.all.flatMap { [$0.face, $0.helpPicture] } + FeelingMoment.all.map(\.picture)
        for picture in pictures {
            XCTAssertNotNil(UIImage(named: "Picture-\(picture)"), picture)
        }
    }

    func testCountingThingsFillAWideStripInOneRow() {
        // An iPad on its side: a short, wide space should put five things in one row, as big as the height allows.
        let wide = CountingView.fit(5, in: CGSize(width: 1100, height: 260), gap: 10)
        XCTAssertEqual(wide.columns, 5)
        XCTAssertEqual(wide.side, 240, accuracy: 0.01, "capped")
        // An upright phone: more rows, and everything fits.
        let tall = CountingView.fit(9, in: CGSize(width: 350, height: 500), gap: 10)
        let rows = CGFloat((9 + tall.columns - 1) / tall.columns)
        XCTAssertLessThanOrEqual(tall.side * CGFloat(tall.columns), 350)
        XCTAssertLessThanOrEqual(tall.side * rows, 500)
    }
}
