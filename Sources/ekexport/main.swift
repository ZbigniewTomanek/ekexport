import Foundation
import ArgumentParser

struct EkExport: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "ekexport",
        abstract: "A secure macOS Calendar and Reminders export tool",
        subcommands: [Export.self, ListCalendars.self]
    )
}

EkExport.main()

