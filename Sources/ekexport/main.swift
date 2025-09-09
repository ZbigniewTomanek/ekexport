import Foundation
import ArgumentParser

@available(macOS 10.15, *)
struct EkExport: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "ekexport",
        abstract: "A secure macOS Calendar and Reminders export tool",
        subcommands: [Export.self, ListCalendars.self]
    )
}

let semaphore = DispatchSemaphore(value: 0)

Task {
    await EkExport.main()
    semaphore.signal()
}

semaphore.wait()

