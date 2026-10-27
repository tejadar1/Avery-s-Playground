import XCTest
@testable import AverysPlayground

final class SoundsTests: XCTestCase {
    func testEverySoundIsAudibleAndNeverClips() {
        for sound in Sound.allCases {
            let samples = sound.samples
            XCTAssertGreaterThan(samples.count, 1000, "\(sound)")
            let peak = samples.map { abs($0) }.max() ?? 0
            XCTAssertGreaterThan(peak, 0.2, "\(sound)")
            XCTAssertLessThanOrEqual(peak, 1, "\(sound)")
        }
    }

    func testOnlyOneShotSoundsDontLoop() {
        XCTAssertEqual(Sound.allCases.filter { !$0.loops }, [.pop, .sparkle, .shutter])
    }

    func testEveryTuneIsASoftLoop() {
        for tune in Tune.allCases {
            let samples = tune.samples
            XCTAssertGreaterThan(samples.count, Int(Tune.rate * 10), "\(tune) is long enough not to sound repetitive")
            XCTAssertLessThanOrEqual(samples.map { abs($0) }.max() ?? 1, 0.81, "\(tune)")
        }
    }
}
