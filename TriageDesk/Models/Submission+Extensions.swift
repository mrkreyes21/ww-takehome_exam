import SwiftUI

struct DuplicateMatch: Equatable, Hashable {
    let reason: String
    let matchingCount: Int
}

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
            return Color(red: 0.95, green: 0.42, blue: 0.42)
        case .pending:
            return Color(red: 0.96, green: 0.58, blue: 0.20)
        case .inReview:
            return Color(red: 0.45, green: 0.35, blue: 0.85)
        case .closed:
            return Color(red: 0.45, green: 0.50, blue: 0.55)
        case .reviewed:
            return Color(red: 0.10, green: 0.14, blue: 0.20)
        case .unknown:
            return Color(red: 0.55, green: 0.60, blue: 0.65)
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
    
    // duplicate detection helper comparing all submission fields except name
    func isDuplicate(of other: Submission) -> Bool {
        guard other.id != self.id else { return false }
        
        // must have valid contact details
        guard self.displayEmail != nil || self.displayPhone != nil else { return false }
        guard other.displayEmail != nil || other.displayPhone != nil else { return false }
        
        // 1. email matching
        if let e1 = self.displayEmail?.lowercased(), let e2 = other.displayEmail?.lowercased() {
            guard e1 == e2 else { return false }
        } else if (self.displayEmail != nil) != (other.displayEmail != nil) {
            return false
        }
        
        // 2. phone matching
        if let p1 = self.displayPhone, let p2 = other.displayPhone {
            guard p1 == p2 else { return false }
        } else if (self.displayPhone != nil) != (other.displayPhone != nil) {
            return false
        }
        
        // 3. service category matching
        guard self.displayService == other.displayService else { return false }
        
        // 4. submission timestamp matching
        if let d1 = self.submittedAt, let d2 = other.submittedAt {
            guard abs(d1.timeIntervalSince(d2)) < 60 else { return false }
        } else if (self.submittedAt != nil) != (other.submittedAt != nil) {
            return false
        }
        
        // 5. remote id matching (if present on both)
        if let id1 = self.remoteId, let id2 = other.remoteId {
            guard id1 == id2 else { return false }
        }
        
        // 6. form version matching (if present on both)
        if let f1 = self.formVersion, let f2 = other.formVersion {
            guard f1 == f2 else { return false }
        }
        
        return true
    }
    
    func duplicateMatch(in allSubmissions: [Submission]) -> DuplicateMatch? {
        let matches = matchingDuplicates(in: allSubmissions)
        guard !matches.isEmpty else { return nil }
        return DuplicateMatch(reason: "Identical Submission", matchingCount: matches.count + 1)
    }
    
    func matchingDuplicates(in allSubmissions: [Submission]) -> [Submission] {
        allSubmissions.filter { isDuplicate(of: $0) }
    }
}
