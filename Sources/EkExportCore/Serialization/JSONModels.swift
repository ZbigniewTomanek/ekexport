import Foundation

/// Intermediate structs for JSON serialization that mirror EventKit objects
/// but decouple the JSON schema from internal EventKit structure
public struct JSONRecurrenceRule: Codable {
    public let frequency: String
    public let interval: Int
    public let count: Int?
    
    public init(from model: RecurrenceRuleModel) {
        self.frequency = model.frequency.rawValue
        self.interval = model.interval
        self.count = model.count
    }
}

public struct JSONEvent: Codable {
    public let id: String
    public let calendarId: String
    public let title: String
    public let notes: String?
    public let location: String?
    public let startDate: String
    public let endDate: String
    public let isAllDay: Bool
    public let timeZone: String?
    public let recurrenceRules: [JSONRecurrenceRule]
    
    public init(from model: EventModel) {
        let formatter = ISO8601DateFormatter()
        
        self.id = model.id
        self.calendarId = model.calendarId
        self.title = model.title
        self.notes = model.notes
        self.location = model.location
        self.startDate = formatter.string(from: model.start)
        self.endDate = formatter.string(from: model.end)
        self.isAllDay = model.isAllDay
        self.timeZone = model.timeZoneIdentifier
        self.recurrenceRules = model.recurrenceRules.map(JSONRecurrenceRule.init)
    }
}

public struct JSONReminder: Codable {
    public let id: String
    public let calendarId: String
    public let title: String
    public let notes: String?
    public let dueDate: String?
    public let completedDate: String?
    public let priority: Int?
    public let isCompleted: Bool
    
    public init(from model: ReminderModel) {
        let formatter = ISO8601DateFormatter()
        
        self.id = model.id
        self.calendarId = model.calendarId
        self.title = model.title
        self.notes = model.notes
        self.dueDate = model.dueDate.map(formatter.string)
        self.completedDate = model.completedDate.map(formatter.string)
        self.priority = model.priority
        self.isCompleted = model.completedDate != nil
    }
}

/// Top-level JSON export structure with metadata
public struct JSONExport: Codable {
    public let exportInfo: ExportMetadata
    public let events: [JSONEvent]
    public let reminders: [JSONReminder]
    
    public init(events: [JSONEvent], reminders: [JSONReminder]) {
        self.exportInfo = ExportMetadata(
            timestamp: ISO8601DateFormatter().string(from: Date()),
            eventCount: events.count,
            reminderCount: reminders.count,
            exportedBy: "ekexport"
        )
        self.events = events
        self.reminders = reminders
    }
}

public struct ExportMetadata: Codable {
    public let timestamp: String
    public let eventCount: Int
    public let reminderCount: Int
    public let exportedBy: String
}

/// JSON representation of calendar information for list-calendars command
public struct JSONCalendar: Codable {
    public let id: String
    public let title: String
    public let account: String?
    public let type: String
    public let colorHex: String?
    public let allowsModifications: Bool
    
    public init(from model: CalendarModel) {
        self.id = model.id
        self.title = model.title
        self.account = model.account
        self.type = model.type
        self.colorHex = model.colorHex
        self.allowsModifications = model.allowsModifications
    }
}

/// Top-level JSON structure for calendar listing
public struct JSONCalendarList: Codable {
    public let listInfo: ListMetadata
    public let calendars: [JSONCalendar]
    
    public init(calendars: [JSONCalendar]) {
        self.listInfo = ListMetadata(
            timestamp: ISO8601DateFormatter().string(from: Date()),
            calendarCount: calendars.count,
            listedBy: "ekexport"
        )
        self.calendars = calendars
    }
}

public struct ListMetadata: Codable {
    public let timestamp: String
    public let calendarCount: Int
    public let listedBy: String
}