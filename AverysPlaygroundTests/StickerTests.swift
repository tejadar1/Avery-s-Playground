import XCTest
@testable import AverysPlayground

final class StickerTests: XCTestCase {
    func testWinsAddUpToNewStickersUntilTheBookIsFull() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "StickerTests"))
        defaults.removePersistentDomain(forName: "StickerTests")
        XCTAssertNil(StickerBook.award(in: defaults), "one win isn't enough")
        XCTAssertNotNil(StickerBook.award(in: defaults), "the second win earns the first sticker")
        var seen = Set(StickerBook.earned(in: defaults))
        var wins = 2
        while seen.count < StickerBook.all.count {
            wins += 1
            if let sticker = StickerBook.award(in: defaults) {
                XCTAssertTrue(seen.insert(sticker).inserted, "\(sticker) was given twice")
            }
            XCTAssertLessThan(wins, 1000)
        }
        XCTAssertEqual(wins, (0..<StickerBook.all.count).map { StickerBook.winsNeeded(having: $0) }.reduce(0, +))
        XCTAssertNil(StickerBook.award(in: defaults), "a full book has nothing new")
        XCTAssertEqual(Set(StickerBook.earned(in: defaults)), Set(StickerBook.all))
    }

    func testEveryStickerHasAPicture() {
        for sticker in StickerBook.all {
            XCTAssertNotNil(UIImage(named: "Picture-\(sticker)"), sticker)
        }
    }
}
