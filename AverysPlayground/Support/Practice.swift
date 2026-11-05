import Foundation

/// What she finds tricky, so the learning games bring it back more often: a miss makes an item come up more, a
/// right answer a little less, until it's like any other again. Kept between visits.
enum Practice {
    static let storeKey = "practiceMisses"

    private static var misses: [String: Int] {
        get { UserDefaults.standard.dictionary(forKey: storeKey) as? [String: Int] ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: storeKey) }
    }

    static func missed(_ item: String) { misses[item] = min(4, (misses[item] ?? 0) + 2) }

    static func got(_ item: String) {
        guard let count = misses[item] else { return }
        misses[item] = count > 1 ? count - 1 : nil
    }

    /// How likely an item is to come up: 1 for one she knows, up to 9 for one she keeps missing.
    static func weight(_ item: String) -> Int { 1 + 2 * (misses[item] ?? 0) }

    /// A random item, the tricky ones more likely.
    static func pick<T>(_ items: [T], key: (T) -> String) -> T? {
        guard !items.isEmpty else { return nil }
        let weights = items.map { weight(key($0)) }
        var roll = Int.random(in: 0..<weights.reduce(0, +))
        for (item, weight) in zip(items, weights) {
            if roll < weight { return item }
            roll -= weight
        }
        return items.last
    }
}
