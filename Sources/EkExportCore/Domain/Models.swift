import Foundation

public struct CalendarModel: Sendable, Hashable {
    public let id: String
    public let title: String
    public let account: String?
    public let type: String
    public let colorHex: String?
    public let allowsModifications: Bool

    public init(id: String, title: String, account: String?, type: String, colorHex: String?, allowsModifications: Bool) {
        self.id = id
        self.title = title
        self.account = account
        self.type = type
        self.colorHex = colorHex
        self.allowsModifications = allowsModifications
    }
}

public struct RecurrenceRuleModel: Sendable, Hashable {
    public enum Frequency: String, Sendable { case daily, weekly, monthly, yearly }
    public let frequency: Frequency
    public let interval: Int
    public let count: Int?

    public init(frequency: Frequency, interval: Int, count: Int?) {
        self.frequency = frequency
        self.interval = interval
        self.count = count
    }
}

public struct EventModel: Sendable, Hashable {
    public let id: String
    public let calendarId: String
    public let title: String
    public let notes: String?
    public let location: String?
    public let start: Date
    public let end: Date
    public let isAllDay: Bool
    public let timeZoneIdentifier: String?
    public let recurrenceRules: [RecurrenceRuleModel]

    public init(id: String, calendarId: String, title: String, notes: String?, location: String?, start: Date, end: Date, isAllDay: Bool, timeZoneIdentifier: String?, recurrenceRules: [RecurrenceRuleModel]) {
        self.id = id
        self.calendarId = calendarId
        self.title = title
        self.notes = notes
        self.location = location
        self.start = start
        self.end = end
        self.isAllDay = isAllDay
        self.timeZoneIdentifier = timeZoneIdentifier
        self.recurrenceRules = recurrenceRules
    }
}

public struct ReminderModel: Sendable, Hashable {
    public let id: String
    public let calendarId: String
    public let title: String
    public let notes: String?
    public let dueDate: Date?
    public let completedDate: Date?
    public let priority: Int?

    public init(id: String, calendarId: String, title: String, notes: String?, dueDate: Date?, completedDate: Date?, priority: Int?) {
        self.id = id
        self.calendarId = calendarId
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.completedDate = completedDate
        self.priority = priority
    }
}

