You are an expert macOS developer and system architect with deep experience in Apple frameworks and building production-grade command-line tools. Your task is to conduct in-depth research and create a comprehensive project design document for a CLI tool that securely and reliably exports calendar and reminder data from a user's macOS accounts.


The final design document must be structured precisely into the following sections.


<instructions>
<section title="1. Deep Dive: EventKit API">

<objective>Analyze Apple's EventKit framework on macOS to determine the feasibility and implementation details for data extraction.</objective>

<points>

1. **Core Classes:** Detail the roles and interactions of `EKEventStore`, `EKEvent`, `EKCalendar`, and `EKReminder`.

2. **Data Fetching:** Provide a clear code example and explanation for fetching data within a specific date range using `NSPredicate`.

3. **Authorization Model:** Explain the complete process for a non-GUI, command-line tool to request and persist permissions for Calendar and Reminders data. Clarify the role of the `Info.plist`, the `NSCalendarsUsageDescription` / `NSRemindersUsageDescription` keys, and how the one-time system prompt is handled.

</points>
</section>


<section title="2. CLI Interface and Output Design">

<objective>Design a user-friendly, robust, and scriptable command-line interface for the tool.</objective>

<points>

1. **Command Structure:** Define the command structure, including a primary command and subcommands (e.g., `events`, `reminders`).

2. **Arguments & Options:** Specify the arguments and options, including `--from`, `--to`, `--format` (supporting `json` and `ics`), and `--output` (for file path). Use clear, conventional naming.

3. **Recommended Library:** Research and recommend a modern Swift library for parsing arguments (e.g., Apple's `swift-argument-parser`), and justify your choice.

4. **Output Schema:** Design the schema for the JSON output. Provide a clear example for both a calendar event and a reminder, ensuring all essential fields are included. Also, specify the structure of the `.ics` output.

5. **Error Handling & Exit Codes:** Define a strategy for reporting helpful and detailed errors to `stderr`. Specify a list of distinct exit codes for different failure scenarios (e.g., 1 for permission denied, 2 for invalid arguments, 3 for no data found).

</points>

</section>



<section title="3. Build, Deployment, and Testing">

<objective>Provide a complete, step-by-step guide for building, deploying, and testing the project.</objective>

<points>

1. **Project Setup:** Detail the steps to set up a "Command Line Tool" project in Xcode.

2. **Dependency Management:** Explain how to add and manage dependencies (like `swift-argument-parser`) using Swift Package Manager.

3. **Release Build:** Document the process for compiling and creating a self-contained, optimized, universal release binary that can be easily distributed or copied to `/usr/local/bin`.

4. **Testing Strategy:** Outline a testing plan. This should include unit tests for data transformation logic (e.g., model-to-JSON conversion) and integration tests for the CLI commands, discussing how to mock `EventKit` dependencies to run tests without requiring live user data or permissions.

</points>

</section>



<section title="4. Investigation of Critical Caveats">

<objective>Thoroughly investigate and report on potential blockers and critical considerations.</objective>

<points>

1. **Data Access Scope:** Confirm whether EventKit provides access to data from all account types configured in macOS (iCloud, Google, Exchange, CalDAV). Report any known limitations.

2. **Code Signing:** Explain if code signing is mandatory for the tool to request permissions and function correctly. Detail the behavioral differences between an unsigned, ad-hoc signed, and developer-signed binary on modern macOS regarding permissions.

3. **Non-Interactive Execution:** After the initial one-time permission grant, confirm if the tool can run completely non-interactively (e.g., via a cron job or remote script) without any further GUI interaction.

</points>

</section>



<section title="5. Final Summary: Project Design Document">

<objective>Synthesize all research into a final, consolidated project design document ready for a developer to begin implementation.</objective>

<content>

- **Project Name Suggestion:** (e.g., `ek-export`)

- **Core Features:** A bulleted list of capabilities.

- **Recommended Libraries:** The chosen library for argument parsing.

- **CLI Command Syntax:** A summary of the designed commands and options.

- **Output Schemas:** Example JSON and a description of the `.ics` structure.

- **Error Handling Synopsis:** A summary table of exit codes and their meanings.

- **Build & Deployment Synopsis:** A brief overview of the build and test process.

- **Key Caveats Summary:** A concise list of the most important findings on code signing, permissions, and data access.

</content>
</section>

</instructions>
