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
        if unreviewedOverrides.contains(key) {
            return false
        }
        return submission.status == .reviewed || reviewedKeys.contains(key)
    }
    
    func toggleReview(for submission: Submission) {
        let key = persistenceKey(for: submission)
        if isReviewed(submission) {
            reviewedKeys.remove(key)
            if submission.status == .reviewed {
                unreviewedOverrides.insert(key)
            }
        } else {
            reviewedKeys.insert(key)
            unreviewedOverrides.remove(key)
        }
        saveKeys()
    }
    
    func markAsReviewed(_ submission: Submission) {
        let key = persistenceKey(for: submission)
        reviewedKeys.insert(key)
        unreviewedOverrides.remove(key)
        saveKeys()
    }
    
    func markAsUnreviewed(_ submission: Submission) {
        let key = persistenceKey(for: submission)
        reviewedKeys.remove(key)
        if submission.status == .reviewed {
            unreviewedOverrides.insert(key)
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
            return "remote_\(remoteId)"
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
