import SwiftUI
import XCTest
@testable import AverysPlayground

final class NailTests: XCTestCase {
    func testBrushStartsAndContinuesStrokes() {
        var nail = Nail()
        nail.brush(.red, at: CGPoint(x: 0.1, y: 0.1), startsStroke: true)
        nail.brush(.red, at: CGPoint(x: 0.9, y: 0.9), startsStroke: false)
        nail.brush(.blue, at: CGPoint(x: 0.5, y: 0.5), startsStroke: true)

        XCTAssertEqual(nail.strokes.map(\.points.count), [2, 1])
        XCTAssertEqual(nail.strokes.map(\.color), [.red, .blue])
    }

    func testToolsLayerUpAndRemoverClearsAll() {
        var nail = Nail()
        nail.brush(.red, at: CGPoint(x: 0.5, y: 0.5), startsStroke: true)
        nail.apply(.design(.dots))
        nail.apply(.sticker("⭐️"))
        XCTAssertEqual(nail.design, .dots)
        XCTAssertEqual(nail.sticker, "⭐️")
        XCTAssertEqual(nail.strokes.count, 1, "designs and stickers keep the paint")

        nail.apply(.remover)
        XCTAssertEqual(nail, Nail())
    }
}
