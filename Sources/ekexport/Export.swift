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
        help: "The output directory where files will be saved. Creates the directory if it doesn't exist."
    )
    var outputDir: String?
    
    @Option(
        name: .long,
        help: "The output format. Supported: ics, json."
    )
    var format: ExportFormat = .ics
    
    func run() async throws {
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

        // Serialize using the dedicated serializers
        let outputString: String
        switch format {
        case .ics:
            let icsSerializer = ICSSerializer()
            do {
                outputString = try icsSerializer.serialize(events: evts, reminders: rems)
            } catch let error as SerializationError {
                print("Serialization error: \(error.description)", to: &StandardError.shared)
                throw error
            } catch {
                print("Unknown serialization error: \(error.localizedDescription)", to: &StandardError.shared)
                throw error
            }
        case .json:
            let jsonSerializer = JSONSerializer()
            do {
                outputString = try jsonSerializer.serialize(events: evts, reminders: rems)
            } catch let error as SerializationError {
                print("Serialization error: \(error.description)", to: &StandardError.shared)
                throw error
            } catch {
                print("Unknown serialization error: \(error.localizedDescription)", to: &StandardError.shared)
                throw error
            }
        }

        // Handle output
        if let outputPath = output {
            try outputString.write(toFile: outputPath, atomically: true, encoding: .utf8)
            print("Successfully exported \(evts.count) events\(includeReminders ? ", \(rems.count) reminders" : "") to \(outputPath)", to: &StandardError.shared)
        } else if let outputDirectory = outputDir {
            // Create output directory if it doesn't exist
            let fileManager = FileManager.default
            try fileManager.createDirectory(atPath: outputDirectory, withIntermediateDirectories: true, attributes: nil)
            
            let fileName: String
            switch format {
            case .json:
                fileName = "export.json"
            case .ics:
                fileName = "export.ics"
            }
            
            let outputPath = URL(fileURLWithPath: outputDirectory).appendingPathComponent(fileName).path
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
