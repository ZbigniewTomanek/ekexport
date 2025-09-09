import Foundation

/// Protocol defining the serialization interface for converting events and reminders into various formats
public protocol Serializer {
    /// Serializes events and reminders into the target format
    /// - Parameters:
    ///   - events: Array of EventModel objects to serialize
    ///   - reminders: Array of ReminderModel objects to serialize
    /// - Returns: String representation in the target format
    /// - Throws: SerializationError if serialization fails
    func serialize(events: [EventModel], reminders: [ReminderModel]) throws -> String
}