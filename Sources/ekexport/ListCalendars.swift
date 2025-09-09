import Foundation
import ArgumentParser
import EkExportCore

enum ListFormat: String, CaseIterable, ExpressibleByArgument {
    case table
    case json
}

struct ListCalendars: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list-calendars",
        abstract: "List available calendars and their identifiers"
    )
    
    @Flag(
        help: "Display detailed calendar information, including color and modification permissions."
    )
    var verbose: Bool = false
    
    @Option(
        name: .long,
        help: "The output format. Supported: table, json."
    )
    var format: ListFormat = .table

    func run() async throws {

        let service = EventKitService()
        do {
            try await service.requestIfNeeded(scopes: [.events])
        } catch let e as DataAccessError {
            print(e.description, to: &StandardError.shared)
            throw e
        }

        let calendars = await service.calendars()

        switch format {
        case .table:
            if verbose {
                print("ID             Title                Account         Type       Permissions  Color     ")
                print(String(repeating: "-", count: 85))
                for c in calendars {
                    let perms = c.allowsModifications ? "Read/Write" : "Read Only"
                    let color = c.colorHex ?? ""
                    print("\(c.id.padding(toLength: 15, withPad: " ", startingAt: 0))\(c.title.padding(toLength: 21, withPad: " ", startingAt: 0))\((c.account ?? "").padding(toLength: 16, withPad: " ", startingAt: 0))\(c.type.padding(toLength: 11, withPad: " ", startingAt: 0))\(perms.padding(toLength: 13, withPad: " ", startingAt: 0))\(color)")
                }
            } else {
                print("ID             Title                Account         Type       Permissions ")
                print(String(repeating: "-", count: 75))
                for c in calendars {
                    let perms = c.allowsModifications ? "Read/Write" : "Read Only"
                    print("\(c.id.padding(toLength: 15, withPad: " ", startingAt: 0))\(c.title.padding(toLength: 21, withPad: " ", startingAt: 0))\((c.account ?? "").padding(toLength: 16, withPad: " ", startingAt: 0))\(c.type.padding(toLength: 11, withPad: " ", startingAt: 0))\(perms)")
                }
            }
            
            print("", to: &StandardError.shared)
            print("Use these IDs with the --calendars option in the export command.", to: &StandardError.shared)
            
        case .json:
            let jsonCalendars = calendars.map(JSONCalendar.init)
            let calendarList = JSONCalendarList(calendars: jsonCalendars)
            
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            
            do {
                let data = try encoder.encode(calendarList)
                guard let jsonString = String(data: data, encoding: .utf8) else {
                    throw SerializationError.encodingFailed("Failed to convert JSON data to UTF-8 string")
                }
                print(jsonString)
            } catch let encodingError as EncodingError {
                throw SerializationError.encodingFailed("JSON encoding failed: \(encodingError.localizedDescription)")
            } catch {
                throw SerializationError.encodingFailed("Unknown JSON encoding error: \(error.localizedDescription)")
            }
        }
    }
}
