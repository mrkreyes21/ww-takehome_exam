import SwiftUI

extension SubmissionStatus: CaseIterable {
    public static var allCases: [SubmissionStatus] {
        [.new, .open, .pending, .inReview, .closed, .reviewed, .unknown]
    }
    
    var displayName: String {
        switch self {
        case .new:
            return "New"
        case .open:
            return "Open"
        case .pending:
            return "Pending"
        case .inReview:
            return "In Review"
        case .closed:
            return "Closed"
        case .reviewed:
            return "Reviewed"
        case .unknown:
            return "Unknown"
        }
    }
    
    var systemImage: String {
        switch self {
        case .new:
            return "sparkles"
        case .open:
            return "envelope.badge"
        case .pending:
            return "clock"
        case .inReview:
            return "eye"
        case .closed:
            return "checkmark.circle"
        case .reviewed:
            return "checkmark.circle.fill"
        case .unknown:
            return "questionmark.circle"
        }
    }
    
    var tintColor: Color {
        switch self {
        case .new:
            return .blue
        case .open:
            return .orange
        case .pending:
            return .purple
        case .inReview:
            return .indigo
        case .closed:
            return .gray
        case .reviewed:
            return .green
        case .unknown:
            return .secondary
        }
    }
    
    var capsuleTitle: String {
        switch self {
        case .new:
            return "NEW"
        case .open:
            return "OPEN"
        case .pending:
            return "PENDING"
        case .inReview:
            return "IN REVIEW"
        case .closed:
            return "CLOSED"
        case .reviewed:
            return "REVIEWED"
        case .unknown:
            return "UNKNOWN"
        }
    }
    
    var solidBadgeColor: Color {
        switch self {
        case .new, .open:
            return Color(red: 0.95, green: 0.42, blue: 0.42) // vibrant coral / salmon
        case .pending:
            return Color(red: 0.96, green: 0.58, blue: 0.20) // warm amber
        case .inReview:
            return Color(red: 0.45, green: 0.35, blue: 0.85) // purple / indigo
        case .closed:
            return Color(red: 0.45, green: 0.50, blue: 0.55) // slate
        case .reviewed:
            return Color(red: 0.10, green: 0.14, blue: 0.20) // dark navy / black
        case .unknown:
            return Color(red: 0.55, green: 0.60, blue: 0.65) // muted gray
        }
    }
}

extension Submission {
    var formattedDate: String {
        guard let submittedAt = submittedAt else { return "Date Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: submittedAt)
    }
    
    var formattedFullDate: String {
        guard let submittedAt = submittedAt else { return "Date Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: submittedAt)
    }
    
    var formattedTime: String {
        guard let submittedAt = submittedAt else { return "12:00 AM" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: submittedAt)
    }
    
    var formattedShortTimeOrDate: String {
        guard let submittedAt = submittedAt else { return "12:00 AM" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: submittedAt)
    }
    
    var displayEmail: String? {
        guard let email = email?.trimmingCharacters(in: .whitespacesAndNewlines), !email.isEmpty else {
            return nil
        }
        return email
    }
    
    var displayPhone: String? {
        guard let phone = phone?.trimmingCharacters(in: .whitespacesAndNewlines), !phone.isEmpty, phone.lowercased() != "n/a" else {
            return nil
        }
        return phone
    }
    
    var displayService: String {
        guard let raw = service?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), !raw.isEmpty else {
            return "General Inquiry"
        }
        
        if raw.contains("web") {
            return "Web Development"
        } else if raw.contains("mobile") || raw.contains("app") || raw.contains("ios") || raw.contains("android") {
            return "Mobile App Development"
        } else if raw == "other" {
            return "Other"
        } else {
            return service?.trimmingCharacters(in: .whitespacesAndNewlines).capitalized ?? "General Inquiry"
        }
    }
    
    var serviceIcon: String {
        switch displayService {
        case "Web Development":
            return "globe"
        case "Mobile App Development":
            return "iphone"
        case "Other":
            return "ellipsis.circle"
        default:
            return "briefcase"
        }
    }
    
    var displayMessage: String {
        guard let message = message?.trimmingCharacters(in: .whitespacesAndNewlines), !message.isEmpty else {
            return "No additional message provided."
        }
        return message
    }
    
    var displayFormVersion: String {
        guard let version = formVersion?.trimmingCharacters(in: .whitespacesAndNewlines), !version.isEmpty else {
            return "Legacy"
        }
        return version
    }
    
    func effectiveStatus(in reviewStore: ReviewStore) -> SubmissionStatus {
        if reviewStore.isReviewed(self) {
            return .reviewed
        }
        return self.status
    }
}
