

# **Project Design Document: ekexport \- A Secure macOS Calendar and Reminders Export Tool**

## **1.0 System Architecture and Core Components**

This section outlines the high-level architecture of the ekexport tool, defining its core components and their interactions. The design prioritizes modularity, testability, and a clear separation of concerns, which is essential for building a robust and maintainable production-grade command-line utility. The architecture is designed to isolate complexity, ensuring that dependencies on system frameworks are contained and that the core business logic remains independent and verifiable.

### **1.1 Architectural Overview**

The tool will be implemented using a layered architecture to decouple distinct functional areas. This strategic separation ensures that changes in one layer, such as the introduction of a new output format, have minimal impact on others, like the underlying data access logic. This approach is fundamental to long-term maintainability and extensibility. The architecture comprises four distinct layers:

* **Presentation Layer:** This is the command-line interface (CLI) itself, representing the outermost layer of the application. Its sole responsibility is to interact with the user by parsing command-line arguments, options, and flags, and by presenting formatted output, status messages, and errors. It will be built upon Apple's swift-argument-parser library to provide a robust, declarative, and user-friendly interface.1
* **Logic/Orchestration Layer:** Serving as the application's core, this layer coordinates the overall workflow. It acts as the intermediary between the Presentation Layer and the lower-level services. Upon receiving parsed commands, it orchestrates the process of requesting data from the Data Access Layer, directing the Serialization Layer to format that data, and managing the final output stream (either to a file or standard output).
* **Data Access Layer (DAL):** This layer provides a crucial abstraction over Apple's EventKit framework. It is the only component in the system that communicates directly with the macOS Calendar and Reminders database. Its responsibilities include managing the lifecycle of the EKEventStore, handling all user permission requests and status checks related to the Transparency, Consent, and Control (TCC) framework, and executing data-fetching queries. It translates raw EventKit objects into a clean, domain-specific model for the rest of the application.
* **Serialization Layer:** This layer is responsible for the transformation of the application's internal data models into standardized, portable export formats. It takes the data fetched by the DAL and converts it into user-specified formats, such as the iCalendar (.ics) standard or JSON. This layer is entirely independent of the data source, allowing new formats to be added without altering any data access or business logic.

### **1.2 Core Components and Modules**

The layered architecture is realized through a set of distinct, well-defined components, each with a specific role.

* **ekexport (Main Executable):** This struct serves as the primary entry point for the application. Conforming to the ParsableCommand protocol from swift-argument-parser, its main function is to define the complete command structure, including subcommands like export and list-calendars.1 It is responsible for parsing the command-line arguments provided by the user and delegating the execution flow to the appropriate logic component, such as the
  ExportManager.
* **ExportManager (Logic Layer):** This class encapsulates the primary business logic for the export command. It orchestrates the entire export process from start to finish. Its workflow involves:
  1. Receiving validated and type-safe command-line options (such as date ranges, calendar filters, and output format) from the Presentation Layer.
  2. Invoking the EventKitService to fetch the required EKEvent and EKReminder objects based on the user's criteria.
  3. Instantiating the appropriate Serializer implementation (e.g., ICalSerializer or JSONSerializer) based on the user's format selection.
  4. Passing the fetched data to the selected serializer for conversion.
  5. Managing the final output, writing the serialized string to the specified destination, which could be a file on disk or the standard output stream (stdout).
* **EventKitService (Data Access Layer):** This class is the central and exclusive point of interaction with the EventKit framework. It is designed to encapsulate all the complexities of dealing with the system's calendar database.
  * It will manage a singleton instance of EKEventStore. This design choice is deliberate, as Apple's documentation indicates that EKEventStore is an expensive object to initialize and should be treated as a long-lived object within an application's lifecycle.4
  * It will fully encapsulate all permission-checking and request logic. This abstracts the nuances of the TCC framework away from the rest of the application, presenting a simple, consistent authorization interface.
  * It will expose a set of well-defined, high-level methods for fetching data, such as fetchEvents(in:forCalendars:) and fetchReminders(in:forCalendars:). Internally, these methods will be responsible for constructing and executing the necessary NSPredicate queries to filter the data efficiently.7
* **Serializer (Protocol and Implementations):** To support multiple output formats in a clean and extensible manner, a protocol will define the serialization interface. For example: protocol Serializer { func serialize(events: \[EKEvent\], reminders:) throws \-\> String }.
  * **ICalSerializer:** This will be the primary implementation, conforming to the Serializer protocol. It will contain the sophisticated logic required to convert arrays of EKEvent and EKReminder objects into a single, valid RFC 5545-compliant iCalendar string.9
  * **JSONSerializer:** An alternative implementation will be provided to produce a machine-readable JSON output. This serializer will focus on creating a clean, well-structured representation of the calendar and reminder data.

### **1.3 Dependency Management**

The project will be structured as a Swift Package Manager (SPM) executable project, the modern standard for building Swift applications and tools.11 This approach simplifies dependency management and the overall build process.

The sole external dependency for this project will be apple/swift-argument-parser. This official Apple library is the canonical choice for building robust command-line tools in Swift. The dependency will be declared in the Package.swift manifest, which allows SPM to automatically handle fetching, versioning, and linking the library during the build process, ensuring a straightforward and reproducible development setup.2

### **1.4 Architectural Implications for Testability**

The architectural separation of the Data Access Layer (EventKitService) from the core logic (ExportManager) is not merely an adherence to good software design principles; it is a critical decision that directly enables the comprehensive testing strategy required for a production-grade application. System frameworks like EventKit present significant challenges for automated testing. They are deeply integrated with the operating system, rely on live user data, and are protected by permission systems that are designed to prevent non-interactive access. Attempting to write unit tests that directly invoke EKEventStore methods would result in tests that are unreliable, slow, and dependent on the specific state of the machine on which they are run.

To overcome this, the design employs a protocol-based abstraction, a form of complete mocking.15 The

ExportManager will not depend on the concrete EventKitService class directly. Instead, it will depend on a protocol, for instance EventKitFetching, which defines the contract for data access (e.g., func fetchEvents(...)). In the main application, the EventKitService will be the concrete implementation of this protocol. However, within the test suite, a separate MockEventKitService class will be created. This mock class will also conform to the EventKitFetching protocol but will return pre-defined, predictable data—such as a fixed array of mock EKEvent objects—without ever touching the actual system calendar database.

This design allows the ExportManager's logic—its handling of date ranges, its filtering mechanisms, and its interaction with the Serializer—to be tested in complete isolation from the EventKit framework. This leads to unit tests that are fast, deterministic, and capable of running on any machine, including continuous integration servers. This robust testing foundation, enabled by this specific architectural choice, is a cornerstone of the tool's overall reliability.

## **2.0 Data Access and Abstraction Layer**

This section provides a detailed design for the EventKitService component, which is responsible for all interactions with the user's calendar and reminder database via the EventKit framework. This layer serves as a protective and simplifying wrapper around EventKit, ensuring that its use is safe, efficient, and consistent throughout the application.

### **2.1 Interfacing with EKEventStore**

The EventKitService class will initialize and manage a single, static instance of EKEventStore. This singleton pattern is a direct implementation of Apple's official guidance, which states that an EKEventStore is a heavyweight object that is computationally expensive to create and should therefore be long-lived and shared across the application.4 By centralizing access through a single instance, the design avoids unnecessary performance overhead and ensures a consistent connection to the calendar database.

Furthermore, all interactions with EventKit data objects—such as EKEvent, EKReminder, and EKCalendar—will be strictly managed through this single store instance. Apple's documentation explicitly warns developers not to use an object obtained from one event store with a different event store instance.4 The encapsulation provided by the

EventKitService design inherently enforces this rule, preventing a class of subtle but critical bugs that could arise from mismanaging EventKit objects.

### **2.2 Authorization and Permissions Management (TCC)**

Accessing calendar and reminder data is a privacy-sensitive operation, and macOS strictly controls it through the Transparency, Consent, and Control (TCC) framework. The EventKitService will be solely responsible for managing this security-critical interaction.

The authorization flow will be executed before any attempt to access data. The first step is to check the current authorization status using the class method EKEventStore.authorizationStatus(for:) for both the .event and .reminder entity types.16 The flow proceeds based on the returned status:

* If the status is .notDetermined, it signifies that the user has not yet been asked for permission. The service will then invoke the appropriate request methods: requestFullAccessToEvents(completion:) for calendars and requestFullAccessToReminders(completion:) for reminders.4 A crucial implementation detail for a non-interactive command-line tool is that these methods are asynchronous. The tool's main execution thread would normally exit before the user has a chance to respond to the system's permission dialog. To prevent this premature exit, the main thread must be blocked until the asynchronous completion handler is called. This can be robustly achieved using concurrency primitives like a
  DispatchSemaphore or, more modernly, by wrapping the call in a Swift async function with a CheckedContinuation.19
* If the status is .denied or .restricted, the tool cannot proceed. It must terminate gracefully, printing a clear and actionable error message to the user. This message will instruct the user on how to manually grant permission in System Settings \> Privacy & Security, ensuring they are not left without recourse.

A key requirement for TCC is the inclusion of "usage description" strings. Unlike a standard GUI application, a command-line tool does not have a traditional Info.plist file within an application bundle. To address this, the necessary TCC keys must be embedded directly into the final executable binary. This is accomplished within the Xcode project by creating an Info.plist file and enabling the build setting "Create Info.plist Section in Binary".19 The following keys are mandatory:

* NSCalendarsFullAccessUsageDescription: A string explaining why the tool needs to read and write calendar events.
* NSRemindersFullAccessUsageDescription: A string explaining why the tool needs to read and write reminders.

These strings are displayed directly to the user in the TCC permission prompt and are therefore critical for gaining user trust and consent.16 Omitting these keys will cause the application to crash or for the permission request to fail silently when the request methods are called.20

### **2.3 Data Fetching Strategy**

The EventKitService will employ an efficient, predicate-based strategy for all data fetching operations to minimize performance impact and memory usage.

* **Events:** Calendar events will be fetched using the EKEventStore.events(matching:) method, which requires an NSPredicate as its primary argument.4 This predicate will be constructed using the highly optimized
  EKEventStore.predicateForEvents(withStart:end:calendars:) method.7 This approach delegates the complex task of filtering events by date range and calendar to the EventKit framework itself, which is far more efficient than fetching all events and filtering them in memory.
* **Reminders:** A similar predicate-based approach will be used for reminders. To ensure all reminders are captured regardless of their completion status, the service will construct and combine predicates from methods like predicateForIncompleteReminders(withDueDateStarting:ending:calendars:) and predicateForCompletedReminders(withCompletionDateStarting:ending:calendars:).22 The resulting data will be fetched using the asynchronous
  fetchReminders(matching:completion:) method.22
* **Calendar Filtering:** The tool will allow users to specify which calendars to export from. This will be handled by filtering based on the calendarIdentifier property of the EKCalendar class, which provides a unique identifier for each calendar.24 The
  EventKitService will first retrieve all available calendars for the relevant entity type using calendars(for:).4 It will then validate the user-provided identifiers against this list. Finally, the validated array of
  EKCalendar objects will be passed directly into the predicate creation methods, ensuring the query is precisely targeted.

### **2.4 Object Model Mapping**

To facilitate serialization and internal processing, the EventKitService will be aware of the key properties of the EventKit objects it handles. The design will focus on extracting the following essential attributes:

* **EKCalendar:** title, calendarIdentifier, type (which indicates the account type, such as CalDAV, Exchange, or Local), color (for potential use in verbose output), and source.title (which provides a user-friendly name for the parent account, like "iCloud" or "Google").24
* **EKEvent:** title, startDate, endDate, isAllDay, location, notes, attendees, organizer, recurrenceRules, and alarms. These properties provide a comprehensive representation of a calendar event.5
* **EKReminder:** title, dueDateComponents, isCompleted, completionDate, priority, notes, alarms, and recurrenceRules. These properties cover the essential attributes of a to-do item.28

### **2.5 Addressing Framework Limitations**

A robust design must account for the documented and undocumented limitations of the underlying frameworks. Two such limitations in EventKit are particularly critical for the reliability of ekexport.

First, the documentation for predicateForEvents(withStart:end:calendars:) contains a crucial performance-related constraint: the method will only match events within a four-year time span. If the provided date range is larger than four years, the framework silently shortens it to the first four years of the range.8 A user executing

ekexport export with no date range would reasonably expect all of their historical data to be exported. A naive implementation that passes a very large date range (e.g., from Date.distantPast to Date.distantFuture) to this method would silently fail to export any data outside a narrow four-year window, leading to unexpected data loss and a fundamentally unreliable tool. To mitigate this critical failure mode, the EventKitService must implement a chunking mechanism. When a date range exceeding four years is requested, the service will programmatically divide the total range into a series of sequential, four-year-or-less segments. It will then execute a separate query for each segment and aggregate the results before returning them to the logic layer. This transforms a potential source of catastrophic failure into a transparent and reliable implementation detail.

Second, while the calendarIdentifier property is the canonical way to uniquely identify a calendar, both official documentation and community experience indicate that this identifier is not guaranteed to be stable. It can change, particularly after a full account sync with the server.30 This fragility poses a risk for users who might want to save calendar IDs in scripts or configuration files. While

ekexport itself will not persist configurations, the design must account for this instability to provide a better user experience. The list-calendars command will be designed to output not just the identifier, but also the human-readable title and source.title (account name). This provides the user with a more stable, composite reference. This also informs error handling: if a user provides an identifier that is no longer found, the tool can provide a more helpful error message, potentially suggesting calendars with similar names.

## **3.0 Command-Line Interface (CLI) Design**

This section defines the user-facing interface of ekexport, specifying its commands, arguments, and options. The design is built upon Apple's swift-argument-parser library, which enables a declarative, type-safe, and user-friendly implementation. This choice ensures that the tool will automatically benefit from robust features like help text generation, command-line completion scripts, and clear error handling, all of which are hallmarks of a production-grade CLI tool.1

### **3.1 Command Structure**

The application's entry point will be a ParsableCommand struct named ekexport. To maintain a clean and organized interface, the tool's functionality will be divided into logical subcommands. This is a well-established best practice for command-line tools with multiple distinct operations, as seen in tools like swift package.2 The primary subcommands will be:

* **export**: This is the core command of the tool, responsible for all data extraction and serialization operations.
* **list-calendars**: This is a utility command designed to assist the user by providing the necessary information (specifically, calendar identifiers) required to effectively use the export command.

This subcommand structure provides a clear separation of concerns from the user's perspective and allows for future expansion with new commands without cluttering the main interface.

### **3.2 export Command Specification**

The export command will be highly configurable through a series of options and flags, allowing users to precisely tailor the data they wish to extract.

* \--calendars \<IDs\>: An optional, array-based @Option of type String. This option will accept a comma-separated list of calendar identifiers. If this option is omitted, the tool will default to exporting data from all calendars to which it has read access. The automatically generated help text will explicitly guide users to employ the list-calendars command to discover the correct identifiers to use here.
* \--start-date \<YYYY-MM-DD\> & \--end-date \<YYYY-MM-DD\>: These will be optional @Options of type String. The command's handler logic will be responsible for parsing these ISO 8601 date strings into Date objects. If either or both are omitted, they will default to an "unbounded" range. This unbounded request will be handled by the ExportManager and EventKitService, which will query from the earliest possible event to the latest, implementing the necessary four-year chunking strategy detailed in Section 2.5 to ensure a complete export.
* \--include-reminders: A boolean @Flag. By default, the tool will only export calendar events. When this flag is present on the command line, the export will be expanded to include reminders, which will be serialized as VTODO items in the iCalendar format.
* \--output \<path\>: An optional @Option of type String, with both a short (-o) and long (--output) form. If a file path is provided, the exported data will be written to that file. If this option is omitted, the output will be directed to the standard output stream (stdout). This default behavior is a critical feature for a command-line utility, as it allows ekexport to be composed with other tools using standard shell pipes (e.g., ekexport export | grep "My Meeting").31
* \--format \<ics|json\>: An optional @Option that controls the output format, with a default value of ics. The implementation will use an enum that conforms to ExpressibleByArgument, allowing swift-argument-parser to automatically validate that the user has provided a supported format.

### **3.3 list-calendars Command Specification**

The list-calendars command is a crucial utility for making the main export command usable. It will have no required arguments.

* By default, it will print a formatted table to the console with the following columns, designed to give the user all the necessary information to construct an export command: ID, Title, Account, Type, and Permissions.
* \--verbose: A boolean @Flag. When this flag is included, the command will output a more detailed table, adding columns such as Color (Hex) and a boolean Allows Content Modifications flag, providing advanced users with more context about each calendar.24

### **3.4 User Feedback and Output**

For a non-interactive tool, providing clear feedback is essential. The tool will distinguish between its primary data output and its status or error messages by using separate output streams.

* All progress and status updates (e.g., "Requesting access to calendars...", "Fetching events from 5 calendars...", "Serializing 1,250 items...") will be printed to standard error (stderr). This practice ensures that status messages do not contaminate the data stream being sent to standard output (stdout), which is critical when the output is being piped to another process or redirected to a file.
* Error messages will be descriptive, user-friendly, and actionable. For instance, if a permission denial is encountered, the error message will not simply state "access denied," but will explicitly instruct the user on the remedy: "Please grant access in System Settings \> Privacy & Security \> Calendars."
* Upon successful completion of an export to a file, a confirmation message will be printed to stderr, such as "Successfully exported 1,250 items to /path/to/export.ics".

### **3.5 Table: ekexport Command and Option Specification**

The following table serves as the definitive specification for the ekexport command-line interface. It provides an unambiguous, at-a-glance contract for both the developers implementing the CLI parser and the end-users who will consult the documentation. This formalization of the interface is a key step in ensuring the tool is consistent, stable, and easy to use.

| Command | Argument/Option | swift-argument-parser Type | Description | Default |
| :---- | :---- | :---- | :---- | :---- |
| export | \--calendars \<IDs\> | @Option(name:.long, parsing:.upToNextOption) var calendars: \= | Comma-separated list of calendar identifiers to export. Use list-calendars to find IDs. | All calendars |
|  | \--start-date \<YYYY-MM-DD\> | @Option(name:.long) var startDate: String? | The start date for the export range (inclusive). | Unbounded |
|  | \--end-date \<YYYY-MM-DD\> | @Option(name:.long) var endDate: String? | The end date for the export range (inclusive). | Unbounded |
|  | \--include-reminders | @Flag | Export reminders in addition to calendar events. | Disabled |
|  | \--output \<path\> | @Option(name:.shortAndLong) var output: String? | The file path for the exported data. | stdout |
|  | \--format \<format\> | @Option(name:.long) var format: ExportFormat \=.ics | The output format. Supported: ics, json. | ics |
| list-calendars | \--verbose | @Flag | Display detailed calendar information, including color and modification permissions. | Disabled |

## **4.0 Data Serialization and Export Formats**

This section details the process of converting the native EventKit objects fetched from the calendar database into standardized, portable file formats. The primary and default format will be the universally recognized iCalendar standard, ensuring maximum compatibility with other calendar applications. A secondary JSON format will be provided as a machine-friendly alternative for developers and data processing pipelines.

### **4.1 iCalendar (RFC 5545\) Implementation**

The ICalSerializer component will be responsible for the complex task of converting EventKit data into the iCalendar format. The output will be a single .ics file containing multiple VEVENT components (for EKEvent objects) and, if requested, VTODO components (for EKReminder objects). All components will be correctly wrapped within a single top-level BEGIN:VCALENDAR...END:VCALENDAR block, as specified by the standard.9

The mapping from EventKit properties to iCalendar properties will be as follows:

* **EKEvent to VEVENT Mapping:**
  * eventIdentifier will be mapped to the UID property. This is critical for ensuring a globally unique identifier for each event, which is essential for synchronization and de-duplication in other calendar clients.
  * title will be mapped to SUMMARY.
  * notes will be mapped to DESCRIPTION, allowing for longer, multi-line details.
  * startDate and endDate will be mapped to DTSTART and DTEND, respectively.
  * location will be mapped to LOCATION.
  * recurrenceRules will be mapped to the RRULE property. This is a non-trivial conversion that requires translating the structured EKRecurrenceRule object into the compact string format defined by RFC 5545\.
  * All date-time values will be meticulously formatted according to the iCalendar standard (e.g., YYYYMMDDTHHMMSSZ for UTC time). The serializer will respect the timeZone property of each EKEvent and include appropriate TZID parameters where necessary to preserve time zone information accurately.
* **EKReminder to VTODO Mapping:**
  * calendarItemIdentifier will be mapped to UID.
  * title will be mapped to SUMMARY.
  * notes will be mapped to DESCRIPTION.
  * dueDateComponents will be converted to a Date and mapped to the DUE property.
  * completionDate will be mapped to the COMPLETED property.
  * priority will be mapped to the PRIORITY property. This will require a mapping from EventKit's integer-based priority scale (EKReminderPriority) to the 1-9 integer scale defined in RFC 5545\.33

To ensure strict compliance with the iCalendar standard, the development process for the ICalSerializer will involve validation against an external tool or library, such as the one provided by icalendar.org.10 This validation is essential for guaranteeing that the output files produced by

ekexport can be reliably imported by a wide range of third-party calendar applications.

### **4.2 JSON Format Implementation**

As a more developer-focused alternative, the JSONSerializer will provide a structured, machine-readable output. This implementation will leverage Swift's powerful Codable protocol to ensure a safe, simple, and maintainable serialization process.

To achieve this, a set of intermediate structs will be defined within the application. These structs will be designed to be Codable and will mirror the relevant properties of EKEvent and EKReminder. This approach decouples the final JSON output schema from the internal structure of the EventKit objects. This is an important design choice, as it allows the JSON schema to remain stable and versioned, even if the underlying EventKit framework changes in future OS updates.

The top-level JSON object will have a clear structure, containing two primary keys: events and reminders. The value for each key will be an array of objects, where each object represents a single event or reminder with its properties serialized as key-value pairs.

### **4.3 Implementation Considerations for iCalendar Complexity**

The iCalendar specification (RFC 5545\) is notoriously complex, particularly in its handling of recurrence rules (RRULE) and time zones. A naive implementation that relies on simple string concatenation to build the .ics file is highly susceptible to subtle formatting errors that would render the output invalid or cause it to be misinterpreted by other calendar clients.

The conversion of an EKRecurrenceRule object, which has distinct properties for frequency, interval, days of the week, and end conditions, into the compact RRULE string format (e.g., FREQ=WEEKLY;BYDAY=MO,WE,FR;UNTIL=...) is a prime example of this complexity. This translation requires careful logic to handle all possible combinations of recurrence parameters correctly. Similarly, iCalendar has extremely strict requirements for date-time formatting, including the mandatory Z suffix for UTC times and the use of TZID parameters for floating times. Swift's ISO8601DateFormatter must be configured with a precise custom format string to produce compliant output.

Given this complexity, the ICalSerializer component is identified as one of the most challenging parts of the project. It will require a significant allocation of development and, most importantly, testing time. The unit tests for this component will be extensive, covering a wide range of edge cases, including complex recurrence patterns, all-day events spanning daylight saving time transitions, and events with non-standard time zones. The robustness of this single component is paramount to the overall reliability of the tool's primary feature.

## **5.0 Security, Build, and Distribution**

This section addresses the critical non-functional requirements that elevate ekexport from a simple script to a production-grade utility. It covers the procedures for ensuring the tool is trusted by the operating system, is compatible with all modern Mac hardware, and is resilient to runtime failures.

### **5.1 Code Signing and TCC Persistence**

For a non-interactive command-line tool that requires access to protected user data, code signing is not merely a distribution requirement—it is a core functional necessity for ensuring reliable and persistent permissions. macOS's TCC framework is designed to grant permissions not just to a path on the filesystem, but to a verifiable, cryptographically signed piece of code.

When a user first grants ekexport access to their calendars or reminders, TCC records this permission in its secure database. Crucially, this database entry includes not only the application's identifier but also a "code signing requirement" (csreq).35 This

csreq is a representation of the binary's code signature. On subsequent launches, the TCC daemon (tccd) verifies that the running binary's signature matches the csreq stored in its database. If they match, access is granted non-interactively. If they do not match, the user is prompted for permission again, as TCC treats it as a different, untrusted application.37

An unsigned or ad-hoc signed binary has an unstable signature that can change each time it is rebuilt. This would force the user to re-authorize the tool frequently, especially after updates, defeating the goal of creating a reliable tool suitable for scripting and automation. Therefore, the ekexport binary must be signed with a **Developer ID Application** certificate obtained from a paid Apple Developer Program account. This provides a stable, verifiable identity that TCC can trust across updates.

The code signing process will be integrated into the release build script. After the universal binary is created, the codesign command-line tool will be used to apply the signature.38 The command will be similar to:

codesign \--force \--options runtime \--sign "Developer ID Application: Your Name (TEAMID)" /path/to/ekexport
The \--options runtime flag enables the hardened runtime, which is a modern security best practice for macOS applications.

### **5.2 Building a Universal Binary**

To ensure that ekexport runs natively and with maximum performance on all modern Mac computers, it will be compiled and distributed as a universal binary, containing executable code for both Apple Silicon (arm64) and Intel-based (x86\_64) architectures.39

The build process will be automated via a script that performs the following steps:

1. Compile the project for the arm64 architecture using the Swift Package Manager build command: swift build \--arch arm64 \--configuration release.
2. Compile the project again, this time for the x86\_64 architecture: swift build \--arch x86\_64 \--configuration release.
3. Use Apple's lipo command-line tool to merge the two resulting architecture-specific binaries into a single, universal executable file.39 The command will be:
   lipo \-create \-output ekexport.build/arm64-apple-macosx/release/ekexport.build/x86\_64-apple-macosx/release/ekexport.
4. As a final verification step, the script will run lipo \-info ekexport to confirm that the output file correctly contains both x86\_64 and arm64 slices.

This process results in a single, portable executable that can be distributed to any user, regardless of their Mac's underlying processor architecture.

### **5.3 Error Handling and Reliability**

A production-grade CLI tool must be robust and provide clear feedback when errors occur. This is especially important for tools intended for use in automated scripts.

* **Exit Codes:** The tool will use a well-defined set of exit codes to signal its status upon termination. A successful execution will exit with code 0\. Specific failure modes will be assigned unique non-zero exit codes (e.g., 1 for permission denied, 2 for invalid arguments, 3 for file I/O error), allowing scripts to programmatically detect and handle different types of errors.
* **Error Reporting:** All throwing functions within the Swift code, such as those related to file I/O or data serialization, will be wrapped in do-catch blocks. When an error is caught, it will be logged to the standard error stream (stderr) with a specific and user-friendly message. Examples of such messages include:
  * Error: Access to Reminders has been denied by the user. Please grant access in System Settings \> Privacy & Security \> Reminders.
  * Error: The specified calendar with ID 'XYZ' could not be found. Use the 'ekexport list-calendars' command to see available calendars.
  * Error: Failed to write to the output file at '/path/to/locked/file.ics'. Permission denied.

This approach to error handling ensures that the user is never left with a silent failure and is always provided with the necessary information to diagnose and resolve the problem.

## **6.0 Testing Strategy**

A multi-faceted testing strategy is essential to guarantee the correctness, reliability, and robustness of the ekexport tool. This strategy will encompass unit tests for isolated components, integration tests to verify component interactions, and end-to-end (E2E) tests to validate the final compiled binary in a realistic environment.

### **6.1 Unit Testing**

Unit tests will focus on the core logic components that can be tested in complete isolation from the macOS environment and system frameworks.

* **Target Components:** The primary targets for unit testing are the ExportManager and the Serializer implementations.
* **ICalSerializer Tests:** These tests are of paramount importance due to the complexity of the iCalendar format. The test suite will involve creating mock EKEvent and EKReminder objects with a wide variety of attributes and then asserting that the ICalSerializer produces a syntactically correct and semantically accurate iCalendar string. Test cases will cover:
  * Standard and all-day events.
  * Complex recurring events (e.g., weekly on multiple days, monthly by position).
  * Events with special characters in titles or notes.
  * Events in various time zones and across daylight saving time boundaries.
* **JSONSerializer Tests:** Similar tests will be written for the JSONSerializer, asserting that the generated JSON output conforms to the expected schema and accurately reflects the input data.
* **CLI Argument Parsing:** The swift-argument-parser library provides a mechanism for testing the parser configuration without executing the full command. Tests will be written to call ekexport.parse(\[...\]) with various arrays of command-line strings and assert that the correct subcommand struct is initialized with the expected values for its properties. This validates the entire CLI surface area, including options, flags, and argument validation.

### **6.2 Mocking the Data Access Layer**

As established in Section 1.4, directly testing components that depend on EKEventStore is impractical and unreliable. The testing strategy will therefore rely heavily on a protocol-based mocking approach.

* **Protocol-Based Mocking:** An EventKitFetching protocol will be defined to abstract the public methods of the EventKitService (e.g., fetchEvents, fetchReminders, getAuthorizationStatus). The ExportManager will be architected to depend on this protocol, not on the concrete EventKitService class.
* **MockEventKitService:** A mock class, MockEventKitService, will be created within the test target. This class will implement the EventKitFetching protocol. It will be configurable to return pre-defined, canned data (e.g., a specific array of mock events when fetchEvents is called) and to record which of its methods were called and with what parameters. This "complete mocking" strategy allows the ExportManager to be unit-tested thoroughly and deterministically, verifying its logic in isolation from the live calendar database.15

### **6.3 Integration and End-to-End (E2E) Testing**

E2E tests are designed to validate the compiled binary as a whole, ensuring that all the individual components—from argument parsing to data fetching and serialization—work together correctly as a complete application.

* **Test Harness:** A test harness will be created using a scripting language (such as Shell or a Swift test that uses the Process API). This harness will be responsible for executing the compiled ekexport binary with a variety of command-line arguments and inspecting its output, exit code, and any files it creates.
* **E2E Test Scenarios:**
  1. **Happy Path:** Execute ekexport export \--output test.ics and validate that the test.ics file is created and that its contents are valid and match an expected baseline. This may require setting up a dedicated calendar account with known data for testing purposes.
  2. **Argument Validation:** Execute the binary with invalid arguments (e.g., a malformed date string, an unsupported format) and assert that the tool exits with the correct non-zero error code and prints a helpful, user-friendly error message to stderr.
  3. **Permission Flow:** This is the most complex E2E test. The test harness will use the tccutil command-line utility (tccutil reset Calendars com.yourcompany.ekexport) to programmatically reset TCC permissions for the test binary. It will then execute the binary and verify that the system correctly prompts for permission. This test may require a semi-automated environment to handle the UI interaction of the permission prompt.
  4. **Piping and stdout:** Test the standard output functionality by executing a command like ekexport export | grep "SUMMARY:Important Meeting" and asserting that the command pipeline succeeds and finds the expected content. This validates that stderr is being used correctly for non-data output.

## **7.0 Conclusions**

The design outlined in this document provides a comprehensive blueprint for the development of ekexport, a secure, reliable, and production-grade command-line tool for exporting calendar and reminder data from macOS. The architecture is founded on modern Swift development practices, prioritizing modularity, testability, and a deep respect for the macOS security and privacy model.

The key takeaways from this design process are:

1. **EventKit as an Abstraction is Powerful but Nuanced:** The EventKit framework provides a potent abstraction layer, enabling access to a wide variety of user accounts (iCloud, Google, Exchange) without requiring service-specific integrations.17 However, this power is balanced by critical limitations, such as the four-year fetching window 8 and the potential instability of calendar identifiers.30 A successful implementation must be defensively coded to handle these nuances gracefully, as detailed in the chunking and identification strategies.
2. **Security and Permissions are a Core Functional Requirement:** For a non-interactive tool accessing sensitive data, macOS's TCC framework is the most significant architectural constraint. The relationship between a stable Developer ID code signature and the persistence of TCC permissions is paramount.35 Treating code signing as a mere distribution step, rather than a core functional requirement for reliability, would result in a tool that fails to meet its primary objective of seamless, automated operation.
3. **A Protocol-Oriented Architecture is Essential for Testability:** The difficulty of testing against live system frameworks necessitates an architecture built on protocol-based abstraction. By decoupling the core application logic from the EventKitService via the EventKitFetching protocol, the design ensures that the tool's logic can be rigorously and reliably verified through unit tests using mock objects.15 This is the cornerstone of the project's quality assurance strategy.

By adhering to this design, the resulting ekexport tool will not only be functionally complete but also robust, secure, and user-friendly, meeting the high standards expected of a professional macOS utility.

#### **Cytowane prace**

1. Getting Started with ArgumentParser | Documentation \- Apple, otwierano: września 9, 2025, [https://apple.github.io/swift-argument-parser/documentation/argumentparser/gettingstarted/](https://apple.github.io/swift-argument-parser/documentation/argumentparser/gettingstarted/)
2. apple/swift-argument-parser: Straightforward, type-safe ... \- GitHub, otwierano: września 9, 2025, [https://github.com/apple/swift-argument-parser](https://github.com/apple/swift-argument-parser)
3. Create command line tools with Swift, otwierano: września 9, 2025, [https://swift.org/get-started/command-line-tools/](https://swift.org/get-started/command-line-tools/)
4. EKEventStore | Apple Developer Documentation, otwierano: września 9, 2025, [https://developer.apple.com/documentation/eventkit/ekeventstore](https://developer.apple.com/documentation/eventkit/ekeventstore)
5. Discover Calendar and EventKit \- WWDC23 \- Videos \- Apple Developer, otwierano: września 9, 2025, [https://developer.apple.com/videos/play/wwdc2023/10052/](https://developer.apple.com/videos/play/wwdc2023/10052/)
6. EventKit Tutorial: Making a Calendar Reminder \- Kodeco, otwierano: września 9, 2025, [https://www.kodeco.com/2291-eventkit-tutorial-making-a-calendar-reminder](https://www.kodeco.com/2291-eventkit-tutorial-making-a-calendar-reminder)
7. Fetching events from the user's calendar \- Create with Swift, otwierano: września 9, 2025, [https://www.createwithswift.com/fetching-events-from-the-users-calendar/](https://www.createwithswift.com/fetching-events-from-the-users-calendar/)
8. predicateForEvents(withStart:end:calendars:) | Apple Developer Documentation, otwierano: września 9, 2025, [https://developer.apple.com/documentation/eventkit/ekeventstore/predicateforevents(withstart:end:calendars:)](https://developer.apple.com/documentation/eventkit/ekeventstore/predicateforevents\(withstart:end:calendars:\))
9. iCalendar \- Wikipedia, otwierano: września 9, 2025, [https://en.wikipedia.org/wiki/ICalendar](https://en.wikipedia.org/wiki/ICalendar)
10. iCalendar (RFC 5545), otwierano: września 9, 2025, [https://icalendar.org/RFC-Specifications/iCalendar-RFC-5545/](https://icalendar.org/RFC-Specifications/iCalendar-RFC-5545/)
11. How to make a command line tool in Xcode \- DEV Community, otwierano: września 9, 2025, [https://dev.to/ceri\_anne\_dev/how-to-make-a-command-line-tool-in-xcode-2f81](https://dev.to/ceri_anne_dev/how-to-make-a-command-line-tool-in-xcode-2f81)
12. Swift Package Manager \- Documentation, otwierano: września 9, 2025, [https://docs.swift.org/swiftpm/documentation/packagemanagerdocs/](https://docs.swift.org/swiftpm/documentation/packagemanagerdocs/)
13. Adding package dependencies to your app | Apple Developer Documentation, otwierano: września 9, 2025, [https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app)
14. Managing package dependencies with Swift Package Manager (SwiftPM) in Xcode, otwierano: września 9, 2025, [https://alexandersandberg.com/articles/managing-package-dependencies-with-swift-package-manager-in-xcode/](https://alexandersandberg.com/articles/managing-package-dependencies-with-swift-package-manager-in-xcode/)
15. Mocking in Swift | Swift by Sundell, otwierano: września 9, 2025, [https://www.swiftbysundell.com/articles/mocking-in-swift/](https://www.swiftbysundell.com/articles/mocking-in-swift/)
16. authorizationStatus(for:) | Apple Developer Documentation, otwierano: września 9, 2025, [https://developer.apple.com/documentation/eventkit/ekeventstore/authorizationstatus(for:)](https://developer.apple.com/documentation/eventkit/ekeventstore/authorizationstatus\(for:\))
17. Building Local Calendar Sync Day 01: Creating a new project and ..., otwierano: września 9, 2025, [https://pumpingco.de/blog/building-local-calendar-sync-day-01-creating-a-new-project-and-exploring-eventkit-2/](https://pumpingco.de/blog/building-local-calendar-sync-day-01-creating-a-new-project-and-exploring-eventkit-2/)
18. TN3152: Migrating to the latest Calendar access levels | Apple Developer Documentation, otwierano: września 9, 2025, [https://developer.apple.com/documentation/technotes/tn3152-migrating-to-the-latest-calendar-access-levels](https://developer.apple.com/documentation/technotes/tn3152-migrating-to-the-latest-calendar-access-levels)
19. EventKit permission problems for Swift Command Line Tool on macOS Big Sur, otwierano: września 9, 2025, [https://stackoverflow.com/questions/69232295/eventkit-permission-problems-for-swift-command-line-tool-on-macos-big-sur](https://stackoverflow.com/questions/69232295/eventkit-permission-problems-for-swift-command-line-tool-on-macos-big-sur)
20. Accessing Calendar using EventKit and EventKitUI | Apple ..., otwierano: września 9, 2025, [https://developer.apple.com/documentation/EventKit/accessing-calendar-using-eventkit-and-eventkitui](https://developer.apple.com/documentation/EventKit/accessing-calendar-using-eventkit-and-eventkitui)
21. Unable to ask for calendar permission on macOs : r/SwiftUI \- Reddit, otwierano: września 9, 2025, [https://www.reddit.com/r/SwiftUI/comments/1j1zetb/unable\_to\_ask\_for\_calendar\_permission\_on\_macos/](https://www.reddit.com/r/SwiftUI/comments/1j1zetb/unable_to_ask_for_calendar_permission_on_macos/)
22. eventsMatchingPredicate: | Apple Developer Documentation, otwierano: września 9, 2025, [https://developer.apple.com/documentation/eventkit/ekeventstore/events(matching:)?language=objc](https://developer.apple.com/documentation/eventkit/ekeventstore/events\(matching:\)?language=objc)
23. SwiftUI: A Simple Copy Cat of the Calendar \+ Reminder App | by Itsuki \- Level Up Coding, otwierano: września 9, 2025, [https://levelup.gitconnected.com/swiftui-a-simple-copy-cat-of-the-calendar-reminder-app-17e0ec20dffe](https://levelup.gitconnected.com/swiftui-a-simple-copy-cat-of-the-calendar-reminder-app-17e0ec20dffe)
24. EKCalendar | Apple Developer Documentation, otwierano: września 9, 2025, [https://developer.apple.com/documentation/eventkit/ekcalendar](https://developer.apple.com/documentation/eventkit/ekcalendar)
25. How to access an EKCalendar's \`account\` property \- Stack Overflow, otwierano: września 9, 2025, [https://stackoverflow.com/questions/6417632/how-to-access-an-ekcalendars-account-property](https://stackoverflow.com/questions/6417632/how-to-access-an-ekcalendars-account-property)
26. EKEvent | Apple Developer Documentation, otwierano: września 9, 2025, [https://developer.apple.com/documentation/eventkit/ekevent?language=objc](https://developer.apple.com/documentation/eventkit/ekevent?language=objc)
27. Chapter 32\. Calendar \- apeth.com, otwierano: września 9, 2025, [https://www.apeth.com/iOSBook/ch32.html](https://www.apeth.com/iOSBook/ch32.html)
28. EKReminder | Apple Developer Documentation, otwierano: września 9, 2025, [https://developer.apple.com/documentation/eventkit/ekreminder](https://developer.apple.com/documentation/eventkit/ekreminder)
29. Accessing Reminders with EventKit (part 1\) \- This Is My Blog, otwierano: września 9, 2025, [https://kykim.github.io/blog/2012/10/09/accessing-reminders-with-eventkit-part-1/](https://kykim.github.io/blog/2012/10/09/accessing-reminders-with-eventkit-part-1/)
30. How to identify an EKCalendar to store a user calendar selection \- Stack Overflow, otwierano: września 9, 2025, [https://stackoverflow.com/questions/64167707/how-to-identify-an-ekcalendar-to-store-a-user-calendar-selection](https://stackoverflow.com/questions/64167707/how-to-identify-an-ekcalendar-to-store-a-user-calendar-selection)
31. Execute commands and run tools in Terminal on Mac \- Apple Support, otwierano: września 9, 2025, [https://support.apple.com/guide/terminal/execute-commands-and-run-tools-apdb66b5242-0d18-49fc-9c47-a2498b7c91d5/mac](https://support.apple.com/guide/terminal/execute-commands-and-run-tools-apdb66b5242-0d18-49fc-9c47-a2498b7c91d5/mac)
32. what does non-interactive command line tool means? \- Stack Overflow, otwierano: września 9, 2025, [https://stackoverflow.com/questions/16456857/what-does-non-interactive-command-line-tool-means](https://stackoverflow.com/questions/16456857/what-does-non-interactive-command-line-tool-means)
33. EKReminderPriority | Apple Developer Documentation, otwierano: września 9, 2025, [https://developer.apple.com/documentation/eventkit/ekreminderpriority](https://developer.apple.com/documentation/eventkit/ekreminderpriority)
34. RFC Specifications \- iCalendar.org, otwierano: września 9, 2025, [https://icalendar.org/iCalendar-RFC-5545](https://icalendar.org/iCalendar-RFC-5545)
35. A deep dive into macOS TCC.db \- Rainforest QA Blog | Software Testing Guides, otwierano: września 9, 2025, [https://www.rainforestqa.com/blog/macos-tcc-db-deep-dive](https://www.rainforestqa.com/blog/macos-tcc-db-deep-dive)
36. How to get csreq of macOS application on command line? \- Stack Overflow, otwierano: września 9, 2025, [https://stackoverflow.com/questions/52706542/how-to-get-csreq-of-macos-application-on-command-line](https://stackoverflow.com/questions/52706542/how-to-get-csreq-of-macos-application-on-command-line)
37. macOS TCC \- HackTricks \- GitBook, otwierano: września 9, 2025, [https://angelica.gitbook.io/hacktricks/macos-hardening/macos-security-and-privilege-escalation/macos-security-protections/macos-tcc](https://angelica.gitbook.io/hacktricks/macos-hardening/macos-security-and-privilege-escalation/macos-security-protections/macos-tcc)
38. Mac OS | Signing Code from the Command Line \- DigiCert Knowledge Base, otwierano: września 9, 2025, [https://knowledge.digicert.com/tutorials/mac-os-sign-code-command-line](https://knowledge.digicert.com/tutorials/mac-os-sign-code-command-line)
39. Building a universal macOS binary | Apple Developer Documentation, otwierano: września 9, 2025, [https://developer.apple.com/documentation/apple-silicon/building-a-universal-macos-binary?changes=la](https://developer.apple.com/documentation/apple-silicon/building-a-universal-macos-binary?changes=la)
40. Appendix B—Building macOS Universal Components \- Omnis Studio, otwierano: września 9, 2025, [https://www.omnis.net/developers/resources/onlinedocs/ExtcompSDK/ABBuildingMacOSUniversalComps.html](https://www.omnis.net/developers/resources/onlinedocs/ExtcompSDK/ABBuildingMacOSUniversalComps.html)
41. A Universal Binary SPM Command Line Tool for Intel and M1 Macs, otwierano: września 9, 2025, [https://povio.com/blog/introducing-a-universal-binary-spm-command-line-tool-for-intel-and-m1-macs](https://povio.com/blog/introducing-a-universal-binary-spm-command-line-tool-for-intel-and-m1-macs)\
