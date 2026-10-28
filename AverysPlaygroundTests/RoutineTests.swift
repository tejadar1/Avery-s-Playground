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

    func testAGrownUpsOrderIsKeptAndNewStepsGoLast() {
        let kind = RoutineKind.bedtime
        let order = ["Story", "Bath"]
        let steps = kind.steps(in: order).map(\.name)
        XCTAssertEqual(Array(steps.prefix(2)), order)
        XCTAssertEqual(Array(steps.dropFirst(2)), kind.steps.map(\.name).filter { !order.contains($0) }, "the rest keep their usual order")
        XCTAssertEqual(Routine(kind, order: order).steps.first?.name, "Story")
    }
}
