import Foundation
import Combine

enum ViewLayoutMode: String, CaseIterable, Identifiable {
    case list = "List"
    case table = "Table"
    
    var id: String { rawValue }
    
    var systemImage: String {
        switch self {
        case .list:
            return "list.bullet"
        case .table:
            return "tablecells"
        }
    }
}

enum ReviewFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case unreviewedOnly = "Unreviewed"
    case reviewedOnly = "Reviewed"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .all:
            return "line.3.horizontal.decrease.circle"
        case .unreviewedOnly:
            return "clock.badge.exclamationmark"
        case .reviewedOnly:
            return "checkmark.circle.fill"
        }
    }
}

enum StatusFilter: Hashable, Identifiable {
    case all
    case status(SubmissionStatus)
    
    var id: String {
        switch self {
        case .all:
            return "all"
        case .status(let status):
            return status.rawValue
        }
    }
    
    var displayName: String {
        switch self {
        case .all:
            return "All Statuses"
        case .status(let status):
            return status.displayName
        }
    }
}

enum SortOption: String, CaseIterable, Identifiable {
    case newestFirst = "Newest Date"
    case oldestFirst = "Oldest Date"
    case nameAscending = "Name (A-Z)"
    case nameDescending = "Name (Z-A)"
    
    var id: String { rawValue }
    
    var systemImage: String {
        switch self {
        case .newestFirst:
            return "arrow.down"
        case .oldestFirst:
            return "arrow.up"
        case .nameAscending:
            return "textformat.abc"
        case .nameDescending:
            return "textformat.abc"
        }
    }
}

final class SubmissionListViewModel: ObservableObject {
    @Published var submissions: [Submission] = []
    @Published var searchText: String = ""
    @Published var selectedStatusFilter: StatusFilter = .all
    @Published var selectedReviewFilter: ReviewFilter = .all
    @Published var selectedSortOption: SortOption = .newestFirst
    @Published var layoutMode: ViewLayoutMode = .list
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private let dataLoadService: DataLoadServiceProtocol
    
    init(dataLoadService: DataLoadServiceProtocol = DataLoadService()) {
        self.dataLoadService = dataLoadService
        loadSubmissions()
    }
    
    func loadSubmissions() {
        isLoading = true
        errorMessage = nil
        
        do {
            let loaded = try dataLoadService.loadSubmissions(from: "submissions")
            self.submissions = loaded
            self.isLoading = false
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
    
    func filteredSubmissions(reviewStore: ReviewStore) -> [Submission] {
        var result = submissions
        
        // 1. Text Search Filter (name, email, phone, service, message, remoteId)
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !trimmedSearch.isEmpty {
            result = result.filter { submission in
                let nameMatch = submission.name.lowercased().contains(trimmedSearch)
                let emailMatch = submission.email?.lowercased().contains(trimmedSearch) ?? false
                let phoneMatch = submission.phone?.lowercased().contains(trimmedSearch) ?? false
                let serviceMatch = submission.displayService.lowercased().contains(trimmedSearch) || (submission.service?.lowercased().contains(trimmedSearch) ?? false)
                let messageMatch = submission.message?.lowercased().contains(trimmedSearch) ?? false
                let remoteIdMatch = submission.remoteId?.lowercased().contains(trimmedSearch) ?? false
                return nameMatch || emailMatch || phoneMatch || serviceMatch || messageMatch || remoteIdMatch
            }
        }
        
        // 2. Status Filter
        if case .status(let targetStatus) = selectedStatusFilter {
            result = result.filter { $0.status == targetStatus }
        }
        
        // 3. Review State Filter
        switch selectedReviewFilter {
        case .all:
            break
        case .unreviewedOnly:
            result = result.filter { !reviewStore.isReviewed($0) }
        case .reviewedOnly:
            result = result.filter { reviewStore.isReviewed($0) }
        }
        
        // 4. Sorting
        switch selectedSortOption {
        case .newestFirst:
            result.sort { ($0.submittedAt ?? .distantPast) > ($1.submittedAt ?? .distantPast) }
        case .oldestFirst:
            result.sort { ($0.submittedAt ?? .distantPast) < ($1.submittedAt ?? .distantPast) }
        case .nameAscending:
            result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .nameDescending:
            result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
        }
        
        return result
    }
    
    func unreviewedCount(reviewStore: ReviewStore) -> Int {
        submissions.filter { !reviewStore.isReviewed($0) }.count
    }
    
    func reviewedCount(reviewStore: ReviewStore) -> Int {
        submissions.filter { reviewStore.isReviewed($0) }.count
    }
    
    var totalCount: Int {
        submissions.count
    }
}
