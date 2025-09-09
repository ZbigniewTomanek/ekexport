import Foundation

#if canImport(EventKit)
import EventKit

enum Mappers {
    static func calendar(_ ek: EKCalendar) -> CalendarModel {
        CalendarModel(
            id: ek.calendarIdentifier,
            title: ek.title,
            account: ek.source.title,
            type: ek.source.sourceType.label,
            colorHex: ek.cgColor?.toHexString(),
            allowsModifications: ek.allowsContentModifications
        )
    }

    static func event(_ ek: EKEvent) -> EventModel {
        let rules: [RecurrenceRuleModel] = (ek.recurrenceRules ?? []).compactMap { rule in
            guard let freq = rule.frequency.toModel else { return nil }
            return RecurrenceRuleModel(
                frequency: freq,
                interval: Int(rule.interval),
                count: rule.recurrenceEnd?.occurrenceCount
            )
        }
        return EventModel(
            id: ek.eventIdentifier,
            calendarId: ek.calendar.calendarIdentifier,
            title: ek.title ?? "",
            notes: ek.notes,
            location: ek.location,
            start: ek.startDate,
            end: ek.endDate,
            isAllDay: ek.isAllDay,
            timeZoneIdentifier: ek.timeZone?.identifier,
            recurrenceRules: rules
        )
    }

    static func reminder(_ ek: EKReminder) -> ReminderModel {
        let due = ek.dueDateComponents?.date
        return ReminderModel(
            id: ek.calendarItemIdentifier,
            calendarId: ek.calendar.calendarIdentifier,
            title: ek.title ?? "",
            notes: ek.notes,
            dueDate: due,
            completedDate: ek.isCompleted ? ek.completionDate : nil,
            priority: ek.priority == 0 ? nil : Int(ek.priority)
        )
    }
}

private extension EKSourceType {
    var label: String {
        switch self {
        case .local: return "Local"
        case .exchange: return "Exchange"
        case .calDAV: return "CalDAV"
        case .mobileMe: return "iCloud"
        case .subscribed: return "Subscribed"
        case .birthdays: return "Birthdays"
        @unknown default: return "Unknown"
        }
    }
}

private extension EKRecurrenceFrequency {
    var toModel: RecurrenceRuleModel.Frequency? {
        switch self {
        case .daily: return .daily
        case .weekly: return .weekly
        case .monthly: return .monthly
        case .yearly: return .yearly
        @unknown default: return nil
        }
    }
}

private extension CGColor {
    func toHexString() -> String? {
        guard let components = self.converted(to: CGColorSpaceCreateDeviceRGB(), intent: .defaultIntent, options: nil)?.components else { return nil }
        let r = Int((components[0] * 255.0).rounded())
        let g = Int((components[1] * 255.0).rounded())
        let b = Int((components[2] * 255.0).rounded())
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
#endif

