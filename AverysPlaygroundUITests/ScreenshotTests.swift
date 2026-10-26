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
        try snap("00a-Getting ready", device, dir)
        XCTAssertTrue(app.descendants(matching: .any)["Getting ready"].waitForNonExistence(timeout: 5))
        try snap("00-home", device, dir)

        let games: [(title: String, play: () -> Void)] = [
            ("Nail Salon", {
                self.tap(self.app.buttons["Nail 3"])
                sleep(1)
                let nail = self.find("Big nail")
                for (from, to) in [((0.2, 0.05), (0.25, 0.95)), ((0.5, 0.05), (0.5, 0.95)), ((0.8, 0.05), (0.7, 0.9))] {
                    nail.coordinate(withNormalizedOffset: CGVector(dx: from.0, dy: from.1))
                        .press(forDuration: 0.05, thenDragTo: nail.coordinate(withNormalizedOffset: CGVector(dx: to.0, dy: to.1)))
                }
            }),
            ("Hair Salon", {
                let hair = self.find("Hair")
                hair.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.3))
                    .press(forDuration: 0.05, thenDragTo: hair.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.35)))
                self.tap(self.app.buttons["Scissors"])
                hair.coordinate(withNormalizedOffset: CGVector(dx: 0.15, dy: 0.7))
                    .press(forDuration: 0.05, thenDragTo: hair.coordinate(withNormalizedOffset: CGVector(dx: 0.45, dy: 0.62)))
            }),
            ("Mochi", {
                self.tap(self.app.buttons["Feed"])
                sleep(2)
                let mochi = self.find("Puppy")
                mochi.coordinate(withNormalizedOffset: CGVector(dx: 0.35, dy: 0.35))
                    .press(forDuration: 0.05, thenDragTo: mochi.coordinate(withNormalizedOffset: CGVector(dx: 0.65, dy: 0.4)))
            }),
            ("Read", {
                self.tap(self.button("Three Little Pigs"))
                sleep(1)
                let words = self.find("Words")
                words.coordinate(withNormalizedOffset: CGVector(dx: 0.02, dy: 0.3))
                    .press(forDuration: 0.05, thenDragTo: words.coordinate(withNormalizedOffset: CGVector(dx: 0.45, dy: 0.3)))
            }),
            ("Dress Up", {
                for item in ["Gown", "Hats", "Crown", "Extras", "Wand"] { self.tap(self.app.buttons[item]) }
            }),
            ("Piano", {
                self.tap(self.button("Twinkle Twinkle"))
                for key in ["C", "C", "G", "G"] { self.tap(self.app.buttons[key]) }
            }),
            ("Math", {
                self.tap(self.app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Answer'")).firstMatch)
            }),
            ("Español", { self.tap(self.button("Gracias")) }),
            ("ABC", {}),
            ("1 2 3", {}),
            ("Coloring", {
                let picture = self.find("Picture")
                for (crayon, x, y) in [("Red", 0.56, 0.2), ("Yellow", 0.5, 0.3), ("Green", 0.4, 0.6), ("Orange", 0.5, 0.85)] {
                    self.tap(self.app.buttons[crayon])
                    picture.coordinate(withNormalizedOffset: CGVector(dx: x, dy: y)).tap()
                }
            }),
            ("Draw", {
                let canvas = self.find("Canvas")
                for (crayon, from, to) in [("Coral", (0.2, 0.3), (0.8, 0.35)), ("Navy", (0.3, 0.6), (0.7, 0.8)), ("Teal", (0.15, 0.85), (0.85, 0.15))] {
                    self.tap(self.app.buttons[crayon])
                    canvas.coordinate(withNormalizedOffset: CGVector(dx: from.0, dy: from.1))
                        .press(forDuration: 0.05, thenDragTo: canvas.coordinate(withNormalizedOffset: CGVector(dx: to.0, dy: to.1)))
                }
            }),
            ("Bingo", {
                self.tap(self.app.buttons["Slide!"])
                sleep(1)
                self.tap(self.app.buttons["Slide!"])
            }),
            ("Tic-Tac-Toe", {
                // Stars take the top row while hearts go in the middle.
                for square in [1, 4, 2, 5, 3] { self.tap(self.button("Square \(square)")) }
            }),
        ]

        // Which home-screen choice each game is under (Activity.section in the app).
        let learn = ["Read", "Math", "Español", "ABC", "1 2 3", "Piano"], teamUp = ["Bingo", "Tic-Tac-Toe"]
        for (index, game) in games.enumerated() {
            let choice = learn.contains(game.title) ? "Learn" : teamUp.contains(game.title) ? "Team Up" : "Play"
            tap(app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", choice)).firstMatch)
            sleep(1)
            let tile = button(game.title)
            tap(tile)
            sleep(1)
            game.play()
            sleep(1)
            try snap(String(format: "%02d-%@", index + 1, game.title), device, dir)
            if game.title == "Read" {
                app.navigationBars.buttons.element(boundBy: 0).tap()
                tap(button("Cucarachita"))
                sleep(1)
                let words = find("Words")
                words.coordinate(withNormalizedOffset: CGVector(dx: 0.02, dy: 0.3))
                    .press(forDuration: 0.05, thenDragTo: words.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3)))
                try snap(String(format: "%02db-Read en español", index + 1), device, dir)
            }
            if game.title == "Hair Salon" {
                tap(app.buttons["Styles"])
                tap(app.buttons["Pigtails"])
                tap(app.buttons["Bows"])
                tap(app.buttons["🎀"])
                sleep(1)
                try snap("02b-Hair Salon styled", device, dir)
            }
            if game.title == "Nail Salon" {
                tap(app.buttons["Stickers"])
                tap(find("Big nail"))
                tap(app.buttons["All nails"])
                sleep(1)
                tap(app.buttons["Done!"])
                sleep(1)
                try snap("01b-Nail Salon done", device, dir)
            }
            goHome()
        }
    }

    /// Waits for an element, scrolls it into view if it's off screen, then taps it.
    /// Off the bottom scrolls the page; off the side scrolls the row of tools or crayons it sits in.
    private func tap(_ element: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        guard element.waitForExistence(timeout: 5) else {
            return XCTFail("Couldn't find \(element.description)", file: file, line: line)
        }
        let screen = app.windows.firstMatch.frame
        for _ in 0..<6 where !element.isHittable {
            let frame = element.frame
            let rows = app.scrollViews.containing(NSPredicate(format: "label == %@", element.label))
            let row = rows.element(boundBy: max(0, rows.count - 1))
            if frame.midY > screen.maxY { app.swipeUp() }
            else if frame.midY < screen.minY { app.swipeDown() }
            else if frame.midX > screen.maxX { row.swipeLeft() }
            else if frame.midX < screen.minX { row.swipeRight() }
            else { break }
        }
        element.tap()
    }

    /// An element found by its accessibility identifier, once it has appeared.
    private func find(_ identifier: String, file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
        let element = app.descendants(matching: .any)[identifier]
        if !element.waitForExistence(timeout: 5) {
            XCTFail("Couldn't find \(identifier)", file: file, line: line)
        }
        return element
    }

    private func button(_ text: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
    }

    private func goHome() {
        for _ in 0..<4 where !app.staticTexts["Avery's Playground"].exists {
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }
    }

    private func snap(_ name: String, _ device: String, _ dir: URL) throws {
        try XCUIScreen.main.screenshot().pngRepresentation.write(to: dir.appendingPathComponent("\(device) \(name).png"))
    }
}
