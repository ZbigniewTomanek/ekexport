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
            // Calculate dynamic column widths
            let idWidth = max(14, calendars.map { $0.id.count }.max() ?? 0)
            let titleWidth = max(20, calendars.map { $0.title.count }.max() ?? 0)
            let accountWidth = max(15, calendars.map { ($0.account ?? "").count }.max() ?? 0)
            let typeWidth = max(10, calendars.map { $0.type.count }.max() ?? 0)
            let permsWidth = 11 // "Read/Write" is always the longest
            
            if verbose {
                let colorWidth = 8
                let totalWidth = idWidth + titleWidth + accountWidth + typeWidth + permsWidth + colorWidth + 5
                
                print("ID\(String(repeating: " ", count: idWidth - 2))Title\(String(repeating: " ", count: titleWidth - 5))Account\(String(repeating: " ", count: accountWidth - 7))Type\(String(repeating: " ", count: typeWidth - 4))Permissions Color")
                print(String(repeating: "-", count: totalWidth))
                
                for c in calendars {
                    let perms = c.allowsModifications ? "Read/Write" : "Read Only"
                    let color = c.colorHex ?? ""
                    
                    let truncatedId = String(c.id.prefix(idWidth))
                    let truncatedTitle = String(c.title.prefix(titleWidth))
                    let truncatedAccount = String((c.account ?? "").prefix(accountWidth))
                    let truncatedType = String(c.type.prefix(typeWidth))
                    
                    print("\(truncatedId.padding(toLength: idWidth, withPad: " ", startingAt: 0)) \(truncatedTitle.padding(toLength: titleWidth, withPad: " ", startingAt: 0)) \(truncatedAccount.padding(toLength: accountWidth, withPad: " ", startingAt: 0)) \(truncatedType.padding(toLength: typeWidth, withPad: " ", startingAt: 0)) \(perms.padding(toLength: permsWidth, withPad: " ", startingAt: 0)) \(color)")
                }
            } else {
                let totalWidth = idWidth + titleWidth + accountWidth + typeWidth + permsWidth + 4
                
                print("ID\(String(repeating: " ", count: idWidth - 2))Title\(String(repeating: " ", count: titleWidth - 5))Account\(String(repeating: " ", count: accountWidth - 7))Type\(String(repeating: " ", count: typeWidth - 4))Permissions")
                print(String(repeating: "-", count: totalWidth))
                
                for c in calendars {
                    let perms = c.allowsModifications ? "Read/Write" : "Read Only"
                    
                    let truncatedId = String(c.id.prefix(idWidth))
                    let truncatedTitle = String(c.title.prefix(titleWidth))
                    let truncatedAccount = String((c.account ?? "").prefix(accountWidth))
                    let truncatedType = String(c.type.prefix(typeWidth))
                    
                    print("\(truncatedId.padding(toLength: idWidth, withPad: " ", startingAt: 0)) \(truncatedTitle.padding(toLength: titleWidth, withPad: " ", startingAt: 0)) \(truncatedAccount.padding(toLength: accountWidth, withPad: " ", startingAt: 0)) \(truncatedType.padding(toLength: typeWidth, withPad: " ", startingAt: 0)) \(perms)")
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
