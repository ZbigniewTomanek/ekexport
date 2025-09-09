import Foundation

public enum AuthorizationStatus: Sendable {
    case notDetermined
    case authorized
    case denied
    case restricted
}

public protocol AuthorizationProviding {
    func status(for scope: AuthorizationScope) -> AuthorizationStatus
    func requestIfNeeded(scopes: [AuthorizationScope]) async throws
}

public protocol EventKitServiceProtocol: AuthorizationProviding {
    func calendars() async -> [CalendarModel]
    func events(calendars: [String]?, start: Date?, end: Date?) async throws -> [EventModel]
    func reminders(calendars: [String]?, includeCompleted: Bool, dueStart: Date?, dueEnd: Date?) async throws -> [ReminderModel]
}
