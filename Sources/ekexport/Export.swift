import Foundation
import ArgumentParser

enum ExportFormat: String, CaseIterable, ExpressibleByArgument {
    case ics
    case json
}

struct Export: ParsableCommand {
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
    
    func run() throws {
        print("=== Export Command Arguments ===", to: &StandardError.shared)
        print("Calendars: \(calendars.isEmpty ? "All calendars" : calendars.joined(separator: ", "))", to: &StandardError.shared)
        print("Start Date: \(startDate ?? "Unbounded")", to: &StandardError.shared)
        print("End Date: \(endDate ?? "Unbounded")", to: &StandardError.shared)
        print("Include Reminders: \(includeReminders)", to: &StandardError.shared)
        print("Output: \(output ?? "stdout")", to: &StandardError.shared)
        print("Format: \(format.rawValue)", to: &StandardError.shared)
        print("================================", to: &StandardError.shared)
        
        // For now, just output a sample based on format
        let sampleOutput: String
        switch format {
        case .ics:
            sampleOutput = """
            BEGIN:VCALENDAR
            VERSION:2.0
            PRODID:-//ekexport//EN
            BEGIN:VEVENT
            UID:sample-event-1
            DTSTART:20240101T120000Z
            DTEND:20240101T130000Z
            SUMMARY:Sample Event
            DESCRIPTION:This is a sample event for testing
            END:VEVENT
            END:VCALENDAR
            """
        case .json:
            sampleOutput = """
            {
              "events": [
                {
                  "id": "sample-event-1",
                  "title": "Sample Event",
                  "startDate": "2024-01-01T12:00:00Z",
                  "endDate": "2024-01-01T13:00:00Z",
                  "description": "This is a sample event for testing"
                }
              ],
              "reminders": []
            }
            """
        }
        
        if let outputPath = output {
            try sampleOutput.write(toFile: outputPath, atomically: true, encoding: .utf8)
            print("Successfully exported sample data to \(outputPath)", to: &StandardError.shared)
        } else {
            print(sampleOutput)
        }
    }
}

struct StandardError: TextOutputStream {
    static var shared = StandardError()
    
    func write(_ string: String) {
        fputs(string, stderr)
    }
}