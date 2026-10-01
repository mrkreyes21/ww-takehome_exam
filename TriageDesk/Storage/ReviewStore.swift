import Foundation
import Combine

final class ReviewStore: ObservableObject {
    // stores the keys for instant lookups
    @Published private(set) var reviewedKeys: Set<String> = []
    
    private let userDefaults: UserDefaults
    private let storageKey: String
    
    init(userDefaults: UserDefaults = .standard, storageKey: String = "triagedesk.reviewed_submissions") {
        self.userDefaults = userDefaults
        self.storageKey = storageKey
        self.loadReviewedKeys()
    }
    
    func isReviewed(_ submission: Submission) -> Bool {
        let key = persistenceKey(for: submission)
        return reviewedKeys.contains(key)
    }
    
    func toggleReview(for submission: Submission) {
        let key = persistenceKey(for: submission)
        if reviewedKeys.contains(key) {
            reviewedKeys.remove(key)
        } else {
            reviewedKeys.insert(key)
        }
        saveReviewedKeys()
    }
    
    func markAsReviewed(_ submission: Submission) {
        let key = persistenceKey(for: submission)
        reviewedKeys.insert(key)
        saveReviewedKeys()
    }
    
    func markAsUnreviewed(_ submission: Submission) {
        let key = persistenceKey(for: submission)
        reviewedKeys.remove(key)
        saveReviewedKeys()
    }
    
    func resetAllReviews() {
        reviewedKeys.removeAll()
        saveReviewedKeys()
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
    
    private func loadReviewedKeys() {
        if let savedArray = userDefaults.stringArray(forKey: storageKey) {
            self.reviewedKeys = Set(savedArray)
        } else {
            self.reviewedKeys = []
        }
    }
    
    private func saveReviewedKeys() {
        userDefaults.set(Array(reviewedKeys), forKey: storageKey)
    }
}
