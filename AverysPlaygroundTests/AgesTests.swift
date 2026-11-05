import XCTest
@testable import AverysPlayground

final class AgesTests: XCTestCase {
    func testEachAgeShowsTheGamesThatSuitIt() {
        let all = Activity.allCases.count
        XCTAssertEqual(all - Ages.suggestedHidden(for: "2").count, 23)
        XCTAssertEqual(all - Ages.suggestedHidden(for: "3").count, 31)
        XCTAssertTrue(Ages.suggestedHidden(for: "4").isEmpty)
        XCTAssertTrue(Ages.suggestedHidden(for: "5").isEmpty)
        XCTAssertTrue(Ages.suggestedHidden(for: "all").isEmpty, "two kids: every game")

        let two = Ages.suggestedHidden(for: "2")
        XCTAssertTrue(two.isSuperset(of: [.tracing, .maze, .race, .ispy, .rhyme, .patterns, .spelling, .math, .tictactoe]))
        XCTAssertFalse(two.contains(.memory), "Memory is for everyone")
        XCTAssertEqual(Ages.suggestedHidden(for: "3"), [.spelling, .math, .tictactoe])
    }

    func testHiddenGamesAreSavedAndReadBack() {
        let hidden: Set<Activity> = [.math, .maze]
        XCTAssertEqual(Ages.hidden(Ages.store(hidden)), hidden)
        XCTAssertEqual(Ages.hidden(""), [])
        XCTAssertEqual(Ages.hidden("math,notAGame"), [.math], "an old or unknown name is skipped")
        XCTAssertEqual(HomeSection.learn.shown(hiding: "math,spelling").filter { [.math, .spelling].contains($0) }, [])
    }

    func testAYearLaterTheNextAgeIsSuggested() {
        let now = Date(timeIntervalSince1970: 1_000_000_000)
        let year = 365 * 24 * 3600.0
        let ago = { (seconds: Double) in now.timeIntervalSince1970 - seconds }
        XCTAssertNil(Ages.nextAge(after: "2", setOn: ago(year - 3600), now: now), "not yet")
        XCTAssertEqual(Ages.nextAge(after: "2", setOn: ago(year + 3600), now: now), "3")
        XCTAssertEqual(Ages.nextAge(after: "3", setOn: ago(year + 3600), now: now), "4")
        XCTAssertNil(Ages.nextAge(after: "4", setOn: ago(2 * year), now: now), "no new games after 4")
        XCTAssertNil(Ages.nextAge(after: "all", setOn: ago(2 * year), now: now))
        XCTAssertNil(Ages.nextAge(after: "", setOn: 0, now: now))
    }
}
