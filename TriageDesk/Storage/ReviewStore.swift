import Foundation
import Combine

final class ReviewStore: ObservableObject {
    @Published private(set) var reviewedKeys: Set<String> = []
    @Published private(set) var unreviewedOverrides: Set<String> = []
    
    private let userDefaults: UserDefaults
    private let reviewedStorageKey: String
    private let unreviewedStorageKey: String
    
    init(
        userDefaults: UserDefaults = .standard,
        reviewedStorageKey: String = "triagedesk.reviewed_submissions",
        unreviewedStorageKey: String = "triagedesk.unreviewed_overrides"
    ) {
        self.userDefaults = userDefaults
        self.reviewedStorageKey = reviewedStorageKey
        self.unreviewedStorageKey = unreviewedStorageKey
        self.loadKeys()
    }
    
    func isReviewed(_ submission: Submission) -> Bool {
        let key = persistenceKey(for: submission)
        let legacyKey = submission.remoteId.map { "remote_\($0)" } ?? ""
        
        if unreviewedOverrides.contains(key) || (!legacyKey.isEmpty && unreviewedOverrides.contains(legacyKey)) {
            return false
        }
        
        if reviewedKeys.contains(key) || (!legacyKey.isEmpty && reviewedKeys.contains(legacyKey)) {
            return true
        }
        
        return submission.status == .reviewed
    }
    
    func toggleReview(for submission: Submission) {
        let key = persistenceKey(for: submission)
        let legacyKey = submission.remoteId.map { "remote_\($0)" } ?? ""
        
        if isReviewed(submission) {
            reviewedKeys.remove(key)
            if !legacyKey.isEmpty { reviewedKeys.remove(legacyKey) }
            
            if submission.status == .reviewed {
                unreviewedOverrides.insert(key)
                if !legacyKey.isEmpty { unreviewedOverrides.insert(legacyKey) }
            }
        } else {
            reviewedKeys.insert(key)
            if !legacyKey.isEmpty { reviewedKeys.insert(legacyKey) }
            
            unreviewedOverrides.remove(key)
            if !legacyKey.isEmpty { unreviewedOverrides.remove(legacyKey) }
        }
        saveKeys()
    }
    
    func markAsReviewed(_ submission: Submission) {
        let key = persistenceKey(for: submission)
        let legacyKey = submission.remoteId.map { "remote_\($0)" } ?? ""
        
        reviewedKeys.insert(key)
        if !legacyKey.isEmpty { reviewedKeys.insert(legacyKey) }
        
        unreviewedOverrides.remove(key)
        if !legacyKey.isEmpty { unreviewedOverrides.remove(legacyKey) }
        saveKeys()
    }
    
    func markAsUnreviewed(_ submission: Submission) {
        let key = persistenceKey(for: submission)
        let legacyKey = submission.remoteId.map { "remote_\($0)" } ?? ""
        
        reviewedKeys.remove(key)
        if !legacyKey.isEmpty { reviewedKeys.remove(legacyKey) }
        
        if submission.status == .reviewed {
            unreviewedOverrides.insert(key)
            if !legacyKey.isEmpty { unreviewedOverrides.insert(legacyKey) }
        }
        saveKeys()
    }
    
    func resetAllReviews() {
        reviewedKeys.removeAll()
        unreviewedOverrides.removeAll()
        saveKeys()
    }
    
    func persistenceKey(for submission: Submission) -> String {
        if let remoteId = submission.remoteId, !remoteId.isEmpty {
            return "remote_\(remoteId)_\(submission.name)"
        }
        let timestamp = submission.submittedAt?.timeIntervalSince1970 ?? 0
        let name = submission.name
        let message = submission.message ?? ""
        return "fallback_\(name)_\(timestamp)_\(message)"
    }
    
    private func loadKeys() {
        if let savedReviewed = userDefaults.stringArray(forKey: reviewedStorageKey) {
            self.reviewedKeys = Set(savedReviewed)
        } else {
            self.reviewedKeys = []
        }
        if let savedUnreviewed = userDefaults.stringArray(forKey: unreviewedStorageKey) {
            self.unreviewedOverrides = Set(savedUnreviewed)
        } else {
            self.unreviewedOverrides = []
        }
    }
    
    private func saveKeys() {
        userDefaults.set(Array(reviewedKeys), forKey: reviewedStorageKey)
        userDefaults.set(Array(unreviewedOverrides), forKey: unreviewedStorageKey)
    }
}
