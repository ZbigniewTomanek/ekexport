import Foundation

enum Predicates {
    static func validateRange(start: Date?, end: Date?) -> Bool {
        if let s = start, let e = end { return s <= e }
        return true
    }
}

