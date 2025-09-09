import Foundation

public enum DateUtils {
    public static func parseISODate(_ value: String) -> Date? {
        // Expecting YYYY-MM-DD; interpret in local timezone at start of day
        let comps = value.split(separator: "-")
        guard comps.count == 3,
              let y = Int(comps[0]),
              let m = Int(comps[1]),
              let d = Int(comps[2]) else { return nil }
        var dc = DateComponents()
        dc.year = y; dc.month = m; dc.day = d
        dc.hour = 0; dc.minute = 0; dc.second = 0
        return Calendar.current.date(from: dc)
    }
}

