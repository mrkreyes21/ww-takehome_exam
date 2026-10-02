import Foundation

// Standalone Executable Unit Test Suite for TriageDesk Decoding & Normalization
// Note: Constructed with AI assistance for comprehensive edge-case coverage and verification.

struct TestRunner {
    static var passedCount = 0
    static var failedCount = 0
    
    static func assert(_ condition: Bool, _ message: String, file: String = #file, line: Int = #line) {
        if condition {
            passedCount += 1
            print("  ✅ [PASS] \(message)")
        } else {
            failedCount += 1
            print("  ❌ [FAIL] \(message) (\(file):\(line))")
        }
    }
    
    static func assertEqual<T: Equatable>(_ actual: T?, _ expected: T?, _ message: String, file: String = #file, line: Int = #line) {
        if actual == expected {
            passedCount += 1
            print("  ✅ [PASS] \(message)")
        } else {
            failedCount += 1
            print("  ❌ [FAIL] \(message) -> Expected: \(String(describing: expected)), Got: \(String(describing: actual)) (\(file):\(line))")
        }
    }
}

// Models Under Test

enum SubmissionStatus: String, Codable, CaseIterable {
    case new, open, pending, inReview, closed, reviewed, unknown
    
    init(rawValue: String) {
        let cleaned = rawValue.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        switch cleaned {
        case "new": self = .new
        case "open": self = .open
        case "pending": self = .pending
        case "in review", "in_review": self = .inReview
        case "closed": self = .closed
        case "reviewed": self = .reviewed
        default: self = .unknown
        }
    }
    
    var displayName: String {
        switch self {
        case .new: return "New"
        case .open: return "Open"
        case .pending: return "Pending"
        case .inReview: return "In Review"
        case .closed: return "Closed"
        case .reviewed: return "Reviewed"
        case .unknown: return "Unknown"
        }
    }
}

struct DuplicateMatch: Equatable {
    let reason: String
    let matchingCount: Int
}

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
    
    init(from decoder: Decoder) throws {
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
        
        let placeholders = ["n/a", "na", "none", "null", "nil", "-"]
        if placeholders.contains(raw.lowercased()) {
            return nil
        }
        
        var digits = raw.filter { $0.isNumber }
        guard digits.count >= 7 else { return nil }
        
        if digits.hasPrefix("09") && digits.count == 11 {
            digits = "63" + digits.dropFirst()
        } else if digits.hasPrefix("02") && digits.count == 10 {
            digits = "63" + digits.dropFirst()
        } else if digits.hasPrefix("9") && digits.count == 10 {
            digits = "63" + digits
        }
        
        return "+\(digits)"
    }
    
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
    
    var displayEmail: String? {
        guard let email = email?.trimmingCharacters(in: .whitespacesAndNewlines), !email.isEmpty else { return nil }
        return email
    }
    
    var displayPhone: String? {
        guard let phone = phone?.trimmingCharacters(in: .whitespacesAndNewlines), !phone.isEmpty, phone.lowercased() != "n/a" else { return nil }
        return phone
    }
    
    var displayService: String {
        guard let raw = service?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), !raw.isEmpty else { return "General Inquiry" }
        if raw.contains("web") { return "Web Development" }
        if raw.contains("mobile") || raw.contains("app") || raw.contains("ios") || raw.contains("android") { return "Mobile App Development" }
        if raw == "other" { return "Other" }
        return service?.trimmingCharacters(in: .whitespacesAndNewlines).capitalized ?? "General Inquiry"
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

// Test Executions

print("\n🚀 Running TriageDesk Unit Tests (Decoding & Normalization)...\n")

// 1. Phone Normalization Tests
print("📱 Testing Phone Normalization:")
do {
    let jsonMobile = """
    {"name": "Maria Santos", "phone": "09171234567"}
    """.data(using: .utf8)!
    let subMobile = try JSONDecoder().decode(Submission.self, from: jsonMobile)
    TestRunner.assertEqual(subMobile.phone, "+639171234567", "Philippine mobile format '09171234567' -> '+639171234567'")
    
    let jsonLandline = """
    {"name": "Juan Dela Cruz", "phone": "0281234567"}
    """.data(using: .utf8)!
    let subLandline = try JSONDecoder().decode(Submission.self, from: jsonLandline)
    TestRunner.assertEqual(subLandline.phone, "+63281234567", "Philippine landline format '0281234567' -> '+63281234567'")
    
    let jsonInt = """
    {"name": "Ana Reyes", "phone": 9171234567}
    """.data(using: .utf8)!
    let subInt = try JSONDecoder().decode(Submission.self, from: jsonInt)
    TestRunner.assertEqual(subInt.phone, "+639171234567", "Integer phone number in JSON coerced to '+639171234567'")
    
    let placeholders = ["n/a", "na", "none", "null", "nil", "-"]
    for ph in placeholders {
        let jsonPh = """
        {"name": "Placeholder Test", "phone": "\(ph)"}
        """.data(using: .utf8)!
        let subPh = try JSONDecoder().decode(Submission.self, from: jsonPh)
        TestRunner.assertEqual(subPh.phone, nil, "Placeholder phone '\(ph)' stripped to nil")
    }
} catch {
    TestRunner.assert(false, "Phone normalization threw error: \(error)")
}

// 2. Date Parsing Tests
print("\n📅 Testing Multi-Strategy Date Parsing:")
do {
    let jsonISO = """
    {"name": "ISO Test", "submittedAt": "2024-11-03T14:22:00Z"}
    """.data(using: .utf8)!
    let subISO = try JSONDecoder().decode(Submission.self, from: jsonISO)
    TestRunner.assert(subISO.submittedAt != nil, "ISO8601 date parsed successfully")
    
    let jsonTimestamp = """
    {"name": "Timestamp Test", "submittedAt": 1730643720}
    """.data(using: .utf8)!
    let subTimestamp = try JSONDecoder().decode(Submission.self, from: jsonTimestamp)
    TestRunner.assert(subTimestamp.submittedAt != nil, "Unix Epoch timestamp parsed successfully")
    
    let jsonSlash = """
    {"name": "Slash Test", "submittedAt": "2024/10/28"}
    """.data(using: .utf8)!
    let subSlash = try JSONDecoder().decode(Submission.self, from: jsonSlash)
    TestRunner.assert(subSlash.submittedAt != nil, "Slash date format '2024/10/28' parsed successfully")
    
    let jsonEmpty = """
    {"name": "Empty Date Test"}
    """.data(using: .utf8)!
    let subEmpty = try JSONDecoder().decode(Submission.self, from: jsonEmpty)
    TestRunner.assertEqual(subEmpty.submittedAt, nil, "Missing date safely sets submittedAt to nil")
} catch {
    TestRunner.assert(false, "Date parsing threw error: \(error)")
}

// 3. Status Normalization Tests
print("\n🏷️ Testing Status Normalization:")
do {
    let cases: [(raw: String, expected: SubmissionStatus)] = [
        ("new", .new), ("NEW", .new),
        ("open", .open), ("OPEN", .open),
        ("pending", .pending), ("PENDING", .pending),
        ("in review", .inReview), ("in_review", .inReview),
        ("closed", .closed), ("CLOSED", .closed),
        ("reviewed", .reviewed), ("REVIEWED", .reviewed),
        ("unknown", .unknown), ("invalid_status", .unknown), ("", .unknown)
    ]
    
    for c in cases {
        let json = """
        {"name": "Status Test", "status": "\(c.raw)"}
        """.data(using: .utf8)!
        let sub = try JSONDecoder().decode(Submission.self, from: json)
        TestRunner.assertEqual(sub.status, c.expected, "Status string '\(c.raw)' normalized to .\(c.expected)")
    }
} catch {
    TestRunner.assert(false, "Status normalization threw error: \(error)")
}

// 4. Duplicate Detection Tests
print("\n🔍 Testing Duplicate Detection:")
do {
    // Exact duplicate matching all fields except name (e.g., Daniel Tan vs Daniel Tan (dup))
    let json1 = """
    {"id": 8, "name": "Daniel Tan", "email": "daniel.tan@example.com", "phone": "09175550123", "service": "Web Development", "submittedAt": "2024-09-15T11:40:00Z", "formVersion": "v2"}
    """.data(using: .utf8)!
    let json2 = """
    {"id": 8, "name": "Daniel Tan (dup)", "email": "daniel.tan@example.com", "phone": "09175550123", "service": "Web Development", "submittedAt": "2024-09-15T11:40:00Z", "formVersion": "v2"}
    """.data(using: .utf8)!
    
    // Same person submitting a separate follow-up inquiry on a different date (NOT a duplicate)
    let json3 = """
    {"id": 1, "name": "Maria Santos", "email": "maria.santos@example.com", "phone": "+639171234567", "service": "Web Development", "submittedAt": "2024-11-03T14:22:00Z", "formVersion": "v3"}
    """.data(using: .utf8)!
    let json4 = """
    {"id": 4, "name": "maria santos", "email": "maria.santos@example.com", "phone": "+639171234567", "service": "web dev", "submittedAt": "2024-11-04T09:05:00Z", "formVersion": "v3"}
    """.data(using: .utf8)!
    
    // Unique user
    let json5 = """
    {"id": 20, "name": "Erik Salazar", "email": "erik.salazar@example.com", "phone": "+639175556767", "service": "Web Development", "submittedAt": "2024-10-25T12:00:00Z", "formVersion": "v3"}
    """.data(using: .utf8)!
    
    let sub1 = try JSONDecoder().decode(Submission.self, from: json1)
    let sub2 = try JSONDecoder().decode(Submission.self, from: json2)
    let sub3 = try JSONDecoder().decode(Submission.self, from: json3)
    let sub4 = try JSONDecoder().decode(Submission.self, from: json4)
    let sub5 = try JSONDecoder().decode(Submission.self, from: json5)
    
    let all = [sub1, sub2, sub3, sub4, sub5]
    
    let match1 = sub1.duplicateMatch(in: all)
    TestRunner.assertEqual(match1?.reason, "Identical Submission", "Identical submissions matching all fields except name flagged as 'Identical Submission'")
    TestRunner.assertEqual(match1?.matchingCount, 2, "Duplicate match count is 2")
    
    let match2 = sub2.duplicateMatch(in: all)
    TestRunner.assertEqual(match2?.reason, "Identical Submission", "Second duplicate recognized as 'Identical Submission'")
    
    // Same person with different dates/inquiries is NOT duplicate
    let matchSeparateInquiry = sub3.duplicateMatch(in: all)
    TestRunner.assertEqual(matchSeparateInquiry, nil, "Multiple submissions from same user with different dates/content are not duplicates")
    
    let matchUnique = sub5.duplicateMatch(in: all)
    TestRunner.assertEqual(matchUnique, nil, "Unique submission has no duplicate match")
} catch {
    TestRunner.assert(false, "Duplicate detection threw error: \(error)")
}

// 5. Malformed JSON Resilience Tests
print("\n🛡️ Testing Malformed JSON Resilience:")
do {
    let jsonEmpty = "{}".data(using: .utf8)!
    let subEmpty = try JSONDecoder().decode(Submission.self, from: jsonEmpty)
    TestRunner.assertEqual(subEmpty.name, "Unknown Sender", "Empty JSON {} falls back to 'Unknown Sender'")
    TestRunner.assertEqual(subEmpty.status, .unknown, "Empty JSON {} defaults to status .unknown")
    TestRunner.assertEqual(subEmpty.displayService, "General Inquiry", "Empty JSON {} defaults service to 'General Inquiry'")
    
    let jsonIntId = """
    {"id": 1, "name": "Maria Santos"}
    """.data(using: .utf8)!
    let subIntId = try JSONDecoder().decode(Submission.self, from: jsonIntId)
    TestRunner.assertEqual(subIntId.remoteId, "1", "Integer id 1 (Record #1) successfully coerced to string '1'")
    
    let jsonStringId = """
    {"id": "0017", "name": "Cha Villanueva"}
    """.data(using: .utf8)!
    let subStringId = try JSONDecoder().decode(Submission.self, from: jsonStringId)
    TestRunner.assertEqual(subStringId.remoteId, "0017", "String id '0017' (Record #17) decoded with leading zeros preserved")
    
    let jsonNullId = """
    {"id": null, "name": "No ID Person"}
    """.data(using: .utf8)!
    let subNullId = try JSONDecoder().decode(Submission.self, from: jsonNullId)
    TestRunner.assertEqual(subNullId.remoteId, nil, "Null id (Record #30) safely decoded as nil")
} catch {
    TestRunner.assert(false, "Malformed JSON decoding threw error: \(error)")
}

// Final Summary
print("\n========================================")
print("📊 TEST RESULTS: \(TestRunner.passedCount) PASSED, \(TestRunner.failedCount) FAILED")
print("========================================\n")

if TestRunner.failedCount > 0 {
    exit(1)
}
