import XCTest

/// Opens every game, plays a little, and saves screenshots to $SCREENSHOTS_DIR (set by CI).
final class ScreenshotTests: XCTestCase {
    private let app = XCUIApplication()

    func testScreenshots() throws {
        guard let dir = ProcessInfo.processInfo.environment["SCREENSHOTS_DIR"] else {
            throw XCTSkip("Set TEST_RUNNER_SCREENSHOTS_DIR to save screenshots")
        }
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        // iPad is where the app is mostly played, so it's checked both ways up.
        for orientation in isPad ? [UIDeviceOrientation.portrait, .landscapeLeft] : [.portrait] {
            XCUIDevice.shared.orientation = orientation
            let device = !isPad ? "iPhone" : orientation == .portrait ? "iPad" : "iPad landscape"
            try playEveryGame(saving: URL(fileURLWithPath: dir), as: device)
        }
    }

    private func playEveryGame(saving dir: URL, as device: String) throws {
        app.launch()
        try snap("00-home", device, dir)

        let games: [(title: String, play: () -> Void)] = [
            ("Nail Salon", {
                self.app.buttons["Nail 3"].tap()
                sleep(1)
                let nail = self.app.descendants(matching: .any)["Big nail"]
                for (from, to) in [((0.2, 0.05), (0.25, 0.95)), ((0.5, 0.05), (0.5, 0.95)), ((0.8, 0.05), (0.7, 0.9))] {
                    nail.coordinate(withNormalizedOffset: CGVector(dx: from.0, dy: from.1))
                        .press(forDuration: 0.05, thenDragTo: nail.coordinate(withNormalizedOffset: CGVector(dx: to.0, dy: to.1)))
                }
            }),
            ("Hair Salon", {
                let hair = self.app.descendants(matching: .any)["Hair"]
                hair.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.3))
                    .press(forDuration: 0.05, thenDragTo: hair.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.35)))
                self.app.buttons["Scissors"].tap()
                hair.coordinate(withNormalizedOffset: CGVector(dx: 0.15, dy: 0.7))
                    .press(forDuration: 0.05, thenDragTo: hair.coordinate(withNormalizedOffset: CGVector(dx: 0.45, dy: 0.62)))
            }),
            ("Mochi", {
                self.app.buttons["Feed"].tap()
                sleep(2)
                let mochi = self.app.descendants(matching: .any)["Puppy"]
                mochi.coordinate(withNormalizedOffset: CGVector(dx: 0.35, dy: 0.35))
                    .press(forDuration: 0.05, thenDragTo: mochi.coordinate(withNormalizedOffset: CGVector(dx: 0.65, dy: 0.4)))
            }),
            ("Read", {
                self.button("Three Little Pigs").tap()
                sleep(1)
                let words = self.app.descendants(matching: .any)["Words"]
                words.coordinate(withNormalizedOffset: CGVector(dx: 0.02, dy: 0.3))
                    .press(forDuration: 0.05, thenDragTo: words.coordinate(withNormalizedOffset: CGVector(dx: 0.45, dy: 0.3)))
            }),
            ("Español", { self.button("Gracias").tap() }),
            ("ABC", {}),
            ("1 2 3", {}),
            ("Coloring", {
                let picture = self.app.descendants(matching: .any)["Picture"]
                for (crayon, x, y) in [("Pink", 0.56, 0.2), ("Yellow", 0.5, 0.3), ("Green", 0.4, 0.6), ("Orange", 0.5, 0.85)] {
                    self.app.buttons[crayon].tap()
                    picture.coordinate(withNormalizedOffset: CGVector(dx: x, dy: y)).tap()
                }
            }),
            ("Animals", { self.button("Cow").tap() }),
            ("Draw", {
                let canvas = self.app.descendants(matching: .any)["Canvas"]
                for (crayon, from, to) in [("Coral", (0.2, 0.3), (0.8, 0.35)), ("Navy", (0.3, 0.6), (0.7, 0.8)), ("Teal", (0.15, 0.85), (0.85, 0.15))] {
                    self.app.buttons[crayon].tap()
                    canvas.coordinate(withNormalizedOffset: CGVector(dx: from.0, dy: from.1))
                        .press(forDuration: 0.05, thenDragTo: canvas.coordinate(withNormalizedOffset: CGVector(dx: to.0, dy: to.1)))
                }
            }),
            ("Bubbles", { sleep(3) }),
        ]

        for (index, game) in games.enumerated() {
            let tile = button(game.title)
            for _ in 0..<4 where !tile.isHittable { app.swipeUp() }
            tile.tap()
            sleep(1)
            game.play()
            sleep(1)
            try snap(String(format: "%02d-%@", index + 1, game.title), device, dir)
            if game.title == "Hair Salon" {
                app.buttons["Styles"].tap()
                app.buttons["Pigtails"].tap()
                app.buttons["Bows"].tap()
                app.buttons["🎀"].tap()
                sleep(1)
                try snap("02b-Hair Salon styled", device, dir)
            }
            if game.title == "Nail Salon" {
                app.buttons["Stickers"].tap()
                app.descendants(matching: .any)["Big nail"].tap()
                app.buttons["🖐️ All nails"].tap()
                sleep(1)
                app.buttons["Done!"].tap()
                sleep(1)
                try snap("01b-Nail Salon done", device, dir)
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

    private func snap(_ name: String, _ device: String, _ dir: URL) throws {
        try XCUIScreen.main.screenshot().pngRepresentation.write(to: dir.appendingPathComponent("\(device) \(name).png"))
    }
}
