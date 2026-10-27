import UIKit
import XCTest
@testable import AverysPlayground

final class RoutineTests: XCTestCase {
    func testStepsTickOffOnceAndTheNextOneIsTheFirstNotDone() {
        var routine = Routine(.bedtime)
        XCTAssertEqual(routine.next, 0)
        XCTAssertTrue(routine.check(1))
        XCTAssertFalse(routine.check(1), "tapping a done step again does nothing")
        XCTAssertEqual(routine.next, 0, "skipping ahead is fine, the first one still waits")
        for index in RoutineKind.bedtime.steps.indices { _ = routine.check(index) }
        XCTAssertTrue(routine.isDone)
        XCTAssertNil(routine.next)
    }

    func testEveryStepHasAPicture() {
        for kind in RoutineKind.allCases {
            for step in kind.steps {
                XCTAssertNotNil(UIImage(named: "Picture-\(step.picture)"), step.name)
            }
        }
    }
}
