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
}
