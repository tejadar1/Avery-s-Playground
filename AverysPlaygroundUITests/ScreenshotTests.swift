import XCTest

/// Opens every game, plays a little, and saves screenshots to $SCREENSHOTS_DIR (set by CI).
final class ScreenshotTests: XCTestCase {
    private let app = XCUIApplication()

    func testScreenshots() throws {
        guard let dir = ProcessInfo.processInfo.environment["SCREENSHOTS_DIR"] else {
            throw XCTSkip("Set TEST_RUNNER_SCREENSHOTS_DIR to save screenshots")
        }
        app.launch()
        try snap("00-home", to: dir)

        let games: [(title: String, play: () -> Void)] = [
            ("Nail Salon", {
                ["Nail 1", "Nail 2", "Nail 3", "Nail 4", "Nail 5"].forEach { self.app.buttons[$0].tap() }
                self.app.buttons["Designs"].tap()
                self.app.buttons["Nail 2"].tap()
                self.app.buttons["Stickers"].tap()
                self.app.buttons["Nail 5"].tap()
            }),
            ("Read", {
                let letters = self.app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Letter'"))
                for i in 0..<letters.count { letters.element(boundBy: i).tap() }
            }),
            ("Stories", { self.button("Three Little Pigs").tap() }),
            ("Español", { self.button("Gracias").tap() }),
            ("ABC", {}),
            ("1 2 3", {}),
            ("Colors", {}),
            ("Animals", { self.button("Cow").tap() }),
            ("Draw", {
                let from = self.app.coordinate(withNormalizedOffset: CGVector(dx: 0.15, dy: 0.3))
                from.press(forDuration: 0.05, thenDragTo: self.app.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.5)))
            }),
            ("Bubbles", { sleep(3) }),
        ]

        for (index, game) in games.enumerated() {
            let tile = button(game.title)
            if !tile.isHittable { app.swipeUp() }
            tile.tap()
            sleep(1)
            game.play()
            sleep(1)
            try snap(String(format: "%02d-%@", index + 1, game.title), to: dir)
            if game.title == "Nail Salon" {
                app.buttons["Done!"].tap()
                sleep(1)
                try snap("01b-Nail Salon done", to: dir)
            }
            goHome()
        }
    }

    private func button(_ text: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
    }

    private func goHome() {
        for _ in 0..<3 where !app.staticTexts["Avery's Playground"].exists {
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }
    }

    private func snap(_ name: String, to dir: String) throws {
        try XCUIScreen.main.screenshot().pngRepresentation
            .write(to: URL(fileURLWithPath: dir).appendingPathComponent("\(name).png"))
    }
}
