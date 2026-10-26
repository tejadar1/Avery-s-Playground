import UIKit
import XCTest
@testable import AverysPlayground

final class ActivityTests: XCTestCase {
    func testEveryGameHasAnIcon() {
        for activity in Activity.allCases {
            XCTAssertNotNil(UIImage(named: activity.icon), "missing Art/icons/\(activity.rawValue).svg render")
        }
    }

    func testEverySectionHasGames() {
        for section in HomeSection.allCases {
            XCTAssertFalse(section.activities.isEmpty, section.title)
        }
        XCTAssertEqual(HomeSection.allCases.flatMap(\.activities).count, Activity.allCases.count)
    }
}
