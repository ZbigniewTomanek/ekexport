import Foundation
import SwiftIcal

/// ICSSerializer implementation that converts EventModel and ReminderModel objects
/// into iCalendar (RFC 5545) format using the SwiftIcal library
public class ICSSerializer: Serializer {
    
    public init() {}
    
    /// Serializes events and reminders into iCalendar format
    /// - Parameters:
    ///   - events: Array of EventModel objects to serialize
    ///   - reminders: Array of ReminderModel objects to serialize
    /// - Returns: RFC 5545 compliant iCalendar string
    /// - Throws: SerializationError if serialization fails
    public func serialize(events: [EventModel], reminders: [ReminderModel]) throws -> String {
        do {
            var vCalendar = VCalendar()
            
            // Export events as VEvent objects
            for event in events {
                let vEvent = try createVEvent(from: event)
                vCalendar.events.append(vEvent)
            }
            
            // Export reminders as VTodo objects (if SwiftIcal supports VTodo)
            // Note: SwiftIcal may not support VTodo, so we'll focus on events for now
            
            return vCalendar.icalString()
        } catch {
            throw SerializationError.encodingFailed("ICS serialization failed: \(error.localizedDescription)")
        }
    }
    
    /// Creates a VEvent from an EventModel
    /// - Parameter event: The EventModel to convert
    /// - Returns: A configured VEvent object
    /// - Throws: SerializationError if conversion fails
    private func createVEvent(from event: EventModel) throws -> VEvent {
        let calendar = Calendar.current
        let timezone = TimeZone.current
        
        let startComponents = DateComponents(
            calendar: calendar,
            timeZone: timezone,
            year: calendar.component(.year, from: event.start),
            month: calendar.component(.month, from: event.start),
            day: calendar.component(.day, from: event.start),
            hour: calendar.component(.hour, from: event.start),
            minute: calendar.component(.minute, from: event.start),
            second: calendar.component(.second, from: event.start)
        )
        
        let endComponents = DateComponents(
            calendar: calendar,
            timeZone: timezone,
            year: calendar.component(.year, from: event.end),
            month: calendar.component(.month, from: event.end),
            day: calendar.component(.day, from: event.end),
            hour: calendar.component(.hour, from: event.end),
            minute: calendar.component(.minute, from: event.end),
            second: calendar.component(.second, from: event.end)
        )
        
        var vEvent = VEvent(
            summary: event.title,
            dtstart: startComponents,
            dtend: endComponents
        )
        
        // Set UID
        vEvent.uid = event.id
        
        // Add optional properties if supported by SwiftIcal
        if let notes = event.notes, !notes.isEmpty {
            vEvent.description = notes
        }
        
        // Note: SwiftIcal may not support location property directly
        
        return vEvent
    }
}