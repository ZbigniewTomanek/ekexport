import Foundation
#if canImport(EventKit)
import EventKit
#endif

public actor EventKitService: EventKitServiceProtocol {
    #if canImport(EventKit)
    private let store = EKEventStore()
    #endif

    public init() {}

    // MARK: Authorization
    public nonisolated func status(for scope: AuthorizationScope) -> AuthorizationStatus {
        #if canImport(EventKit)
        switch scope {
        case .events:
            switch EKEventStore.authorizationStatus(for: .event) {
            case .notDetermined: return .notDetermined
            case .authorized: return .authorized
            case .fullAccess: return .authorized
            case .writeOnly: return .denied
            case .denied: return .denied
            case .restricted: return .restricted
            @unknown default: return .restricted
            }
        case .reminders:
            switch EKEventStore.authorizationStatus(for: .reminder) {
            case .notDetermined: return .notDetermined
            case .authorized: return .authorized
            case .fullAccess: return .authorized
            case .writeOnly: return .denied
            case .denied: return .denied
            case .restricted: return .restricted
            @unknown default: return .restricted
            }
        }
        #else
        return .restricted
        #endif
    }

    public func requestIfNeeded(scopes: [AuthorizationScope]) async throws {
        #if canImport(EventKit)
        for scope in scopes {
            let current = status(for: scope)
            switch current {
            case .authorized:
                continue
            case .denied:
                throw DataAccessError.denied(scope: scope)
            case .restricted:
                throw DataAccessError.restricted(scope: scope)
            case .notDetermined:
                try await requestAccess(scope: scope)
            }
        }
        #else
        throw DataAccessError.unsupportedOperation("EventKit is not available in this environment")
        #endif
    }

    #if canImport(EventKit)
    private func requestAccess(scope: AuthorizationScope) async throws {
        switch scope {
        case .events:
            let granted = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
                store.requestAccess(to: .event) { granted, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: granted)
                    }
                }
            }
            if !granted { throw DataAccessError.denied(scope: .events) }
        case .reminders:
            let granted = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
                store.requestAccess(to: .reminder) { granted, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: granted)
                    }
                }
            }
            if !granted { throw DataAccessError.denied(scope: .reminders) }
        }
    }
    #endif

    // MARK: Calendars
    public func calendars() async -> [CalendarModel] {
        #if canImport(EventKit)
        let all = store.calendars(for: .event)
        return all.map { Mappers.calendar($0) }
        #else
        return []
        #endif
    }

    // MARK: Events
    public func events(calendars: [String]?, start: Date?, end: Date?) async throws -> [EventModel] {
        guard Predicates.validateRange(start: start, end: end) else { throw DataAccessError.invalidDateRange }
        #if canImport(EventKit)
        let s = start ?? Date.distantPast
        let e = end ?? Date.distantFuture
        let cals: [EKCalendar]?
        if let ids = calendars, !ids.isEmpty {
            let all = store.calendars(for: .event)
            let filtered = all.filter { ids.contains($0.calendarIdentifier) }
            cals = filtered
        } else {
            cals = nil
        }
        let predicate = store.predicateForEvents(withStart: s, end: e, calendars: cals)
        let matches = store.events(matching: predicate)
        return matches.map { Mappers.event($0) }
        #else
        throw DataAccessError.unsupportedOperation("EventKit is not available in this environment")
        #endif
    }

    // MARK: Reminders
    public func reminders(calendars: [String]?, includeCompleted: Bool, dueStart: Date?, dueEnd: Date?) async throws -> [ReminderModel] {
        guard Predicates.validateRange(start: dueStart, end: dueEnd) else { throw DataAccessError.invalidDateRange }
        #if canImport(EventKit)
        let cals: [EKCalendar]?
        if let ids = calendars, !ids.isEmpty {
            let all = store.calendars(for: .reminder)
            let filtered = all.filter { ids.contains($0.calendarIdentifier) }
            cals = filtered
        } else {
            cals = nil
        }
        let predicate = store.predicateForReminders(in: cals)
        let fetched: [EKReminder] = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[EKReminder], Error>) in
            store.fetchReminders(matching: predicate) { reminders in
                continuation.resume(returning: reminders ?? [])
            }
        }
        let filtered = fetched.filter { rem in
            if !includeCompleted && rem.isCompleted { return false }
            if let ds = dueStart, let d = rem.dueDateComponents?.date, d < ds { return false }
            if let de = dueEnd, let d = rem.dueDateComponents?.date, d > de { return false }
            return true
        }
        return filtered.map { Mappers.reminder($0) }
        #else
        throw DataAccessError.unsupportedOperation("EventKit is not available in this environment")
        #endif
    }
}

 
