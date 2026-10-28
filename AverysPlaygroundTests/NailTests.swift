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
        nail.apply(.sticker("star"))
        XCTAssertEqual(nail.design, .dots)
        XCTAssertEqual(nail.stickers.map(\.picture), ["star"])
        XCTAssertEqual(nail.strokes.count, 1, "designs and stickers keep the paint")

        nail.apply(.remover)
        XCTAssertEqual(nail, Nail())
    }

    func testStickersGoWhereTappedAndStayOnTheNail() {
        var nail = Nail()
        nail.stick("heart", at: CGPoint(x: 0.3, y: 0.7))
        XCTAssertEqual(nail.stickers.last?.spot, CGPoint(x: 0.3, y: 0.7))
        nail.stick("star", at: CGPoint(x: 1.4, y: -0.2))
        XCTAssertEqual(nail.stickers.last?.spot, CGPoint(x: 0.82, y: 0.15), "kept inside the nail")
        for _ in 0..<10 { nail.stick("gem", at: CGPoint(x: 0.5, y: 0.5)) }
        XCTAssertEqual(nail.stickers.count, Nail.maxStickers)
    }

    func testGlitterStaysWithItsStroke() {
        var nail = Nail()
        nail.brush(.red, glitter: true, at: CGPoint(x: 0.5, y: 0.5), startsStroke: true)
        nail.brush(.blue, at: CGPoint(x: 0.5, y: 0.5), startsStroke: true)
        XCTAssertEqual(nail.strokes.map(\.glitter), [true, false])
    }

    func testTwoToneGlitterKeepsBothColors() {
        var nail = Nail()
        nail.brush(.pink, glitter: true, tint: .blue, at: CGPoint(x: 0.5, y: 0.5), startsStroke: true)
        XCTAssertEqual(nail.strokes.first?.tint, .blue)
        XCTAssertTrue(Nail.painted(.pink, glitter: true, tint: .blue).strokes.allSatisfy { $0.tint == .blue })
    }

    func testPaintedNailIsOneColorAllOver() {
        let nail = Nail.painted(.red)
        XCTAssertEqual(Set(nail.strokes.map(\.color)), [.red])
        XCTAssertTrue(nail.strokes.allSatisfy { $0.points.first?.y == 0 && $0.points.last?.y == 1 })
    }

    func testNailsSitAtTheFingertipsInsideTheHand() {
        let canvas = CGRect(origin: .zero, size: Hand.canvas)
        let middle = Hand.fingers[2]
        XCTAssertEqual(middle.nailCenter.x, middle.base.x, accuracy: 0.01)
        XCTAssertEqual(middle.base.y - middle.nailCenter.y + middle.nailSize.height / 2, middle.length - 6 + middle.overhang, accuracy: 0.01)
        for finger in Hand.fingers {
            let size = finger.nailSize
            let nail = CGRect(x: finger.nailCenter.x - size.height / 2, y: finger.nailCenter.y - size.height / 2, width: size.height, height: size.height)
            XCTAssertTrue(canvas.contains(nail), "\(finger.base)")
        }
    }
}
