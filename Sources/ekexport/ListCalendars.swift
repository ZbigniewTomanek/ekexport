import Foundation
import ArgumentParser

struct ListCalendars: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list-calendars",
        abstract: "List available calendars and their identifiers"
    )
    
    @Flag(
        help: "Display detailed calendar information, including color and modification permissions."
    )
    var verbose: Bool = false
    
    func run() throws {
        print("=== List Calendars Command Arguments ===", to: &StandardError.shared)
        print("Verbose: \(verbose)", to: &StandardError.shared)
        print("========================================", to: &StandardError.shared)
        
        // Sample calendar data for testing
        let sampleCalendars = [
            (id: "calendar-1", title: "Personal", account: "iCloud", type: "CalDAV", permissions: "Read/Write", color: "#FF5733"),
            (id: "calendar-2", title: "Work", account: "Exchange", type: "Exchange", permissions: "Read/Write", color: "#3366FF"),
            (id: "calendar-3", title: "Holidays", account: "Local", type: "Local", permissions: "Read Only", color: "#33FF66")
        ]
        
        if verbose {
            // Detailed table format
            print("ID             Title                Account         Type       Permissions  Color     ")
            print(String(repeating: "-", count: 85))
            
            for calendar in sampleCalendars {
                print("\(calendar.id.padding(toLength: 15, withPad: " ", startingAt: 0))\(calendar.title.padding(toLength: 21, withPad: " ", startingAt: 0))\(calendar.account.padding(toLength: 16, withPad: " ", startingAt: 0))\(calendar.type.padding(toLength: 11, withPad: " ", startingAt: 0))\(calendar.permissions.padding(toLength: 13, withPad: " ", startingAt: 0))\(calendar.color)")
            }
        } else {
            // Basic table format
            print("ID             Title                Account         Type       Permissions ")
            print(String(repeating: "-", count: 75))
            
            for calendar in sampleCalendars {
                print("\(calendar.id.padding(toLength: 15, withPad: " ", startingAt: 0))\(calendar.title.padding(toLength: 21, withPad: " ", startingAt: 0))\(calendar.account.padding(toLength: 16, withPad: " ", startingAt: 0))\(calendar.type.padding(toLength: 11, withPad: " ", startingAt: 0))\(calendar.permissions)")
            }
        }
        
        print("", to: &StandardError.shared)
        print("Use these IDs with the --calendars option in the export command.", to: &StandardError.shared)
    }
}