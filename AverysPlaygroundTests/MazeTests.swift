import XCTest
@testable import AverysPlayground

final class MazeTests: XCTestCase {
    func testEveryCellIsReachableByExactlyOnePath() {
        for size in 4...8 {
            let maze = Maze(size: size)
            var seen: Set<Maze.Cell> = [maze.start]
            var queue = [maze.start]
            var edges = 0
            while let cell = queue.popLast() {
                for next in maze.passages[cell] ?? [] {
                    XCTAssertTrue(maze.neighbors(of: cell).contains(next), "passages only join neighbors")
                    edges += 1
                    if seen.insert(next).inserted { queue.append(next) }
                }
            }
            XCTAssertEqual(seen.count, size * size, "every cell can be reached")
            XCTAssertEqual(edges / 2, size * size - 1, "no loops, so one way through")
        }
    }

    func testWallsStopMochiAndBackingUpErasesTheTrail() {
        let maze = Maze(size: 5)
        var walk = MazeWalk(maze: maze)
        let blocked = maze.neighbors(of: maze.start).first { !maze.isOpen(maze.start, $0) }
        if let blocked {
            walk.move(toward: blocked)
            XCTAssertEqual(walk.current, maze.start, "a hedge is in the way")
        }
        let open = maze.passages[maze.start]!.first!
        walk.move(toward: open)
        XCTAssertEqual(walk.trail, [maze.start, open])
        walk.move(toward: maze.start)
        XCTAssertEqual(walk.trail, [maze.start], "going back rubs out the trail")
    }

    func testAFingerJustAroundTheCornerStillLeadsHer() {
        let maze = Maze(size: 6)
        let first = maze.passages[maze.start]!.first!
        guard let second = maze.passages[first]!.first(where: { $0 != maze.start }) else { return }
        var walk = MazeWalk(maze: maze)
        walk.move(toward: second)
        XCTAssertEqual(walk.trail, [maze.start, first, second])
    }

    func testFollowingThePathReachesTheBone() {
        let maze = Maze(size: 6)
        // Find the way through, then walk it one cell at a time.
        var from: [Maze.Cell: Maze.Cell] = [:]
        var queue = [maze.start]
        while let cell = queue.first {
            queue.removeFirst()
            for next in maze.passages[cell] ?? [] where from[next] == nil && next != maze.start {
                from[next] = cell
                queue.append(next)
            }
        }
        var way = [maze.goal]
        while let back = from[way.last!] { way.append(back) }
        var walk = MazeWalk(maze: maze)
        for cell in way.reversed().dropFirst() { walk.move(toward: cell) }
        XCTAssertTrue(walk.isDone)
    }
}
