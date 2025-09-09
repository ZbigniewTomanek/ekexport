import Foundation

public enum AuthorizationScope: Sendable {
    case events
    case reminders
}

public enum DataAccessError: Error, CustomStringConvertible, Sendable {
    case notDetermined(scope: AuthorizationScope)
    case denied(scope: AuthorizationScope)
    case restricted(scope: AuthorizationScope)
    case invalidDateRange
    case unsupportedOperation(String)
    case underlying(Error)

    public var description: String {
        switch self {
        case .notDetermined(let scope):
            return "Authorization not determined for \(scope.label)."
        case .denied(let scope):
            return "Access denied for \(scope.label). \(userGuidance)"
        case .restricted(let scope):
            return "Access restricted for \(scope.label). \(userGuidance)"
        case .invalidDateRange:
            return "Invalid date range: start must be <= end."
        case .unsupportedOperation(let msg):
            return "Unsupported operation: \(msg)"
        case .underlying(let error):
            return "Underlying error: \(error.localizedDescription)"
        }
    }

    public var userGuidance: String {
        switch self {
        case .notDetermined(let scope):
            return "Run again to request access for \(scope.label)."
        case .denied(let scope), .restricted(let scope):
            return "Please grant access in System Settings > Privacy & Security > \(scope.settingsLabel)."
        default:
            return ""
        }
    }
}

extension AuthorizationScope {
    var label: String {
        switch self { case .events: return "Calendars"; case .reminders: return "Reminders" }
    }
    var settingsLabel: String {
        switch self { case .events: return "Calendars"; case .reminders: return "Reminders" }
    }
}

