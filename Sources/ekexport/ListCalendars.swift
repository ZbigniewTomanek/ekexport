import Foundation
import ArgumentParser
import EkExportCore

struct ListCalendars: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list-calendars",
        abstract: "List available calendars and their identifiers"
    )
    
    @Flag(
        help: "Display detailed calendar information, including color and modification permissions."
    )
    var verbose: Bool = false

    func run() async throws {
        print("=== List Calendars Command Arguments ===", to: &StandardError.shared)
        print("Verbose: \(verbose)", to: &StandardError.shared)
        print("========================================", to: &StandardError.shared)

        let service = EventKitService()
        do {
            try await service.requestIfNeeded(scopes: [.events])
        } catch let e as DataAccessError {
            print(e.description, to: &StandardError.shared)
            throw e
        }

        let calendars = await service.calendars()

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
    }
}
