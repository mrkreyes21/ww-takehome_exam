import SwiftUI

extension SubmissionStatus: CaseIterable {
    public static var allCases: [SubmissionStatus] {
        [.new, .open, .pending, .inReview, .closed, .unknown]
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
        guard let service = service?.trimmingCharacters(in: .whitespacesAndNewlines), !service.isEmpty else {
            return "General Inquiry"
        }
        return service
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
