import Foundation
import ArgumentParser
import EkExportCore

enum ExportFormat: String, CaseIterable, ExpressibleByArgument {
    case ics
    case json
}

struct Export: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Export calendar events and reminders to various formats"
    )
    
    @Option(
        name: .long,
        parsing: .upToNextOption,
        help: "Comma-separated list of calendar identifiers to export. Use list-calendars to find IDs."
    )
    var calendars: [String] = []
    
    @Option(
        name: .long,
        help: "The start date for the export range (inclusive). Format: YYYY-MM-DD"
    )
    var startDate: String?
    
    @Option(
        name: .long,
        help: "The end date for the export range (inclusive). Format: YYYY-MM-DD"
    )
    var endDate: String?
    
    @Flag(
        help: "Export reminders in addition to calendar events."
    )
    var includeReminders: Bool = false
    
    @Option(
        name: .shortAndLong,
        help: "The file path for the exported data. If not specified, output goes to stdout."
    )
    var output: String?
    
    @Option(
        name: .long,
        help: "The output format. Supported: ics, json."
    )
    var format: ExportFormat = .ics
    
    func run() async throws {
        print("=== Export Command Arguments ===", to: &StandardError.shared)
        print("Calendars: \(calendars.isEmpty ? "All calendars" : calendars.joined(separator: ", "))", to: &StandardError.shared)
        print("Start Date: \(startDate ?? "Unbounded")", to: &StandardError.shared)
        print("End Date: \(endDate ?? "Unbounded")", to: &StandardError.shared)
        print("Include Reminders: \(includeReminders)", to: &StandardError.shared)
        print("Output: \(output ?? "stdout")", to: &StandardError.shared)
        print("Format: \(format.rawValue)", to: &StandardError.shared)
        print("================================", to: &StandardError.shared)
        // Parse dates
        let start: Date? = startDate.flatMap(DateUtils.parseISODate)
        let end: Date? = endDate.flatMap(DateUtils.parseISODate)
        if let s = start, let e = end, s > e {
            throw DataAccessError.invalidDateRange
        }

        let service = EventKitService()
        var scopes: [AuthorizationScope] = [.events]
        if includeReminders { scopes.append(.reminders) }
        do {
            try await service.requestIfNeeded(scopes: scopes)
        } catch let e as DataAccessError {
            print(e.description, to: &StandardError.shared)
            throw e
        }

        // Fetch data
        let evts: [EventModel]
        do {
            evts = try await service.events(calendars: calendars.isEmpty ? nil : calendars, start: start, end: end)
        } catch {
            throw error
        }
        var rems: [ReminderModel] = []
        if includeReminders {
            rems = try await service.reminders(calendars: calendars.isEmpty ? nil : calendars, includeCompleted: false, dueStart: start, dueEnd: end)
        }

        // Temporary serialization until dedicated serializers land
        let outputString: String
        switch format {
        case .ics:
            // Minimal ICS with only VEVENT blocks for demonstration
            var lines: [String] = [
                "BEGIN:VCALENDAR",
                "VERSION:2.0",
                "PRODID:-//ekexport//EN"
            ]
            let dfUTC = ISO8601DateFormatter()
            dfUTC.timeZone = TimeZone(secondsFromGMT: 0)
            func icsDate(_ date: Date) -> String {
                let fmt = DateFormatter()
                fmt.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
                fmt.timeZone = TimeZone(secondsFromGMT: 0)
                return fmt.string(from: date)
            }
            for e in evts {
                lines.append(contentsOf: [
                    "BEGIN:VEVENT",
                    "UID:\(e.id)",
                    "DTSTART:\(icsDate(e.start))",
                    "DTEND:\(icsDate(e.end))",
                    "SUMMARY:\(e.title.replacingOccurrences(of: "\n", with: "\\n"))",
                    "END:VEVENT"
                ])
            }
            lines.append("END:VCALENDAR")
            outputString = lines.joined(separator: "\n")
        case .json:
            let dict: [String: Any] = [
                "events": evts.map { [
                    "id": $0.id,
                    "title": $0.title,
                    "startDate": ISO8601DateFormatter().string(from: $0.start),
                    "endDate": ISO8601DateFormatter().string(from: $0.end),
                    "notes": $0.notes as Any
                ] },
                "reminders": rems.map { [
                    "id": $0.id,
                    "title": $0.title,
                    "dueDate": $0.dueDate.map { ISO8601DateFormatter().string(from: $0) } as Any
                ] }
            ]
            let json = try JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted])
            outputString = String(data: json, encoding: .utf8) ?? "{}"
        }

        if let outputPath = output {
            try outputString.write(toFile: outputPath, atomically: true, encoding: .utf8)
            print("Successfully exported \(evts.count) events\(includeReminders ? ", \(rems.count) reminders" : "") to \(outputPath)", to: &StandardError.shared)
        } else {
            print(outputString)
        }
    }
}

struct StandardError: TextOutputStream {
    static var shared = StandardError()
    
    func write(_ string: String) {
        fputs(string, stderr)
    }
}
