import Foundation

/// JSONSerializer implementation that converts EventModel and ReminderModel objects
/// into structured JSON format using Swift's Codable protocol
public class JSONSerializer: Serializer {
    private let encoder: JSONEncoder
    
    public init() {
        self.encoder = JSONEncoder()
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        // Configure date formatting for any nested Date objects (backup strategy)
        self.encoder.dateEncodingStrategy = .iso8601
    }
    
    /// Serializes events and reminders into JSON format
    /// - Parameters:
    ///   - events: Array of EventModel objects to serialize
    ///   - reminders: Array of ReminderModel objects to serialize
    /// - Returns: Pretty-printed JSON string
    /// - Throws: SerializationError if encoding fails
    public func serialize(events: [EventModel], reminders: [ReminderModel]) throws -> String {
        // Convert domain models to JSON-specific models
        let jsonEvents = events.map(JSONEvent.init)
        let jsonReminders = reminders.map(JSONReminder.init)
        
        // Create the top-level export structure
        let export = JSONExport(events: jsonEvents, reminders: jsonReminders)
        
        do {
            let data = try encoder.encode(export)
            guard let jsonString = String(data: data, encoding: .utf8) else {
                throw SerializationError.encodingFailed("Failed to convert JSON data to UTF-8 string")
            }
            return jsonString
        } catch let encodingError as EncodingError {
            throw SerializationError.encodingFailed("JSON encoding failed: \(encodingError.localizedDescription)")
        } catch {
            throw SerializationError.encodingFailed("Unknown JSON encoding error: \(error.localizedDescription)")
        }
    }
}