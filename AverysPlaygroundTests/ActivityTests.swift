import UIKit
import XCTest
@testable import AverysPlayground

final class ActivityTests: XCTestCase {
    func testEveryGameHasAnIcon() {
        for activity in Activity.allCases {
            XCTAssertNotNil(UIImage(named: activity.icon), "missing Art/icons/\(activity.rawValue).svg render")
        }
    }
}
