import XCTest
@testable import AverysPlayground

final class StickerTests: XCTestCase {
    func testEachWinGivesANewStickerUntilTheBookIsFull() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "StickerTests"))
        defaults.removePersistentDomain(forName: "StickerTests")
        var seen: Set<String> = []
        for _ in StickerBook.all {
            let sticker = try XCTUnwrap(StickerBook.award(in: defaults))
            XCTAssertTrue(seen.insert(sticker).inserted, "\(sticker) was given twice")
        }
        XCTAssertNil(StickerBook.award(in: defaults), "a full book has nothing new")
        XCTAssertEqual(Set(StickerBook.earned(in: defaults)), Set(StickerBook.all))
    }

    func testEveryStickerHasAPicture() {
        for sticker in StickerBook.all {
            XCTAssertNotNil(UIImage(named: "Picture-\(sticker)"), sticker)
        }
    }
}
