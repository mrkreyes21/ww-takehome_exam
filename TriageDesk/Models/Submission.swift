import Foundation

struct Submission: Identifiable, Codable {
    let id: UUID
    let remoteId: String?
    let name: String
    let email: String?
    let phone: String?
    let service: String?
    let status: SubmissionStatus
    let message: String?
    let submittedAt: Date?
    let formVersion: String?
    
    enum CodingKeys: String, CodingKey {
        case remoteId = "id"
        case name, email, phone, service, status, message, submittedAt, formVersion
    }
    
    // handles messy JSON data
    init(from decoder: Decoder) throws {
        // guarantees no crashes on duplicate ids, empty objects, missing keys
        self.id = UUID()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let intId = try? container.decode(Int.self, forKey: .remoteId) {
            self.remoteId = String(intId)
        } else if let stringId = try? container.decode(String.self, forKey: .remoteId) {
            self.remoteId = stringId
        } else {
            self.remoteId = nil
        }
        
        self.phone = Submission.parseAndNormalizePhone(from: container)

        let rawName = try? container.decode(String.self, forKey: .name)
        self.name = rawName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? rawName!.trimmingCharacters(in: .whitespacesAndNewlines) : "Unknown Sender"
        
        self.email = try? container.decode(String.self, forKey: .email)

        self.service = try? container.decode(String.self, forKey: .service)
        self.message = try? container.decode(String.self, forKey: .message)
        self.formVersion = try? container.decode(String.self, forKey: .formVersion)
        
        let rawStatus = (try? container.decode(String.self, forKey: .status)) ?? ""
        self.status = SubmissionStatus(rawValue: rawStatus)
        
        self.submittedAt = Submission.parseMessyDate(from: container)
    }
    
    // messy phone number helper
    private static func parseAndNormalizePhone(from container: KeyedDecodingContainer<CodingKeys>) -> String? {
        let rawPhone: String?
        if let intPhone = try? container.decode(Int.self, forKey: .phone) {
            rawPhone = String(intPhone)
        } else {
            rawPhone = try? container.decode(String.self, forKey: .phone)
        }
        
        guard let raw = rawPhone?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return nil
        }
        
        // filter out 
        let placeholders = ["n/a", "na", "none", "null", "nil", "-"]
        if placeholders.contains(raw.lowercased()) {
            return nil
        }
        
        // extract digits only
        var digits = raw.filter { $0.isNumber }
        guard digits.count >= 7 else { return nil }
        
        // E.164 format
        if digits.hasPrefix("09") && digits.count == 11 {
            digits = "63" + digits.dropFirst()
        } else if digits.hasPrefix("02") && digits.count == 10 {
            digits = "63" + digits.dropFirst()
        } else if digits.hasPrefix("9") && digits.count == 10 {
            digits = "63" + digits
        }
        
        return "+\(digits)"
    }
    
    // messy date helper
    private static func parseMessyDate(from container: KeyedDecodingContainer<CodingKeys>) -> Date? {
        if let timestamp = try? container.decode(Int.self, forKey: .submittedAt) { return Date(timeIntervalSince1970: TimeInterval(timestamp)) }
        guard let dateString = try? container.decode(String.self, forKey: .submittedAt), !dateString.isEmpty else { return nil }
        if let timestamp = TimeInterval(dateString) { return Date(timeIntervalSince1970: timestamp) }
        
        let ISOFormatter = ISO8601DateFormatter()
        if let date = ISOFormatter.date(from: dateString) { return date }
        
        let customFormatter = DateFormatter()
        let formats = ["yyyy-MM-dd'T'HH:mm:ssZ", "yyyy-MM-dd'T'HH:mm:ss", "yyyy/MM/dd", "MM-dd-yyyy", "MMM d, yyyy"]
        for format in formats {
            customFormatter.dateFormat = format
            if let date = customFormatter.date(from: dateString) { return date }
        }
        return nil
    }
}

// status enum
enum SubmissionStatus: String, Codable {
    case new, open, pending, inReview, closed, unknown
    
    init(rawValue: String) {
        let cleaned = rawValue.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        switch cleaned {
        case "new": self = .new
        case "open": self = .open
        case "pending": self = .pending
        case "in review", "in_review": self = .inReview
        case "closed": self = .closed
        default: self = .unknown
        }
    }
}
