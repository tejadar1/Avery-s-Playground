import SwiftUI
import XCTest
@testable import AverysPlayground

final class NailTests: XCTestCase {
    func testToolsLayerUpAndRemoverClearsAll() {
        var nail = Nail()
        nail.apply(.polish(.red))
        nail.apply(.design(.dots))
        nail.apply(.sticker("⭐️"))
        XCTAssertEqual(nail, Nail(color: .red, design: .dots, sticker: "⭐️"))

        nail.apply(.polish(.blue))
        XCTAssertEqual(nail.color, .blue)
        XCTAssertEqual(nail.design, .dots, "repainting keeps the design")

        nail.apply(.remover)
        XCTAssertEqual(nail, Nail())
    }
}
