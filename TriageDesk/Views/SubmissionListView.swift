import SwiftUI

struct SubmissionListView: View {
    @StateObject private var viewModel = SubmissionListViewModel()
    @EnvironmentObject private var reviewStore: ReviewStore
    
    private var filteredList: [Submission] {
        viewModel.filteredSubmissions(reviewStore: reviewStore)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // all / unreviewed / reviewed
                Picker("Review Filter", selection: $viewModel.selectedReviewFilter) {
                    ForEach(ReviewFilter.allCases) { filter in
                        Text(filterLabel(for: filter)).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // content view
                if viewModel.isLoading {
                    ProgressView("Loading submissions...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = viewModel.errorMessage {
                    errorStateView(message: errorMessage)
                } else if filteredList.isEmpty {
                    emptyStateView
                } else {
                    if viewModel.layoutMode == .list {
                        submissionListContent
                    } else {
                        SubmissionTableView(submissions: filteredList)
                    }
                }
            }
            .navigationTitle("Triage Desk")
            .searchable(text: $viewModel.searchText, prompt: "Search by name, email, or message...")
            .toolbar {
                // layout mode toggle (List <-> Table)
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.layoutMode = (viewModel.layoutMode == .list ? .table : .list)
                        }
                    } label: {
                        Image(systemName: viewModel.layoutMode == .list ? "tablecells" : "list.bullet")
                    }
                    .accessibilityLabel(viewModel.layoutMode == .list ? "Switch to Table View" : "Switch to List View")
                }
                
                // status filter menu
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            viewModel.selectedStatusFilter = .all
                        } label: {
                            HStack {
                                Text("All Statuses")
                                if case .all = viewModel.selectedStatusFilter {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        
                        Divider()
                        
                        ForEach(SubmissionStatus.allCases, id: \.self) { status in
                            Button {
                                viewModel.selectedStatusFilter = .status(status)
                            } label: {
                                HStack {
                                    Label(status.displayName, systemImage: status.systemImage)
                                    if case .status(let selected) = viewModel.selectedStatusFilter, selected == status {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Label("Status Filter", systemImage: isStatusFiltered ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }
                }
                
                // sort menu
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        ForEach(SortOption.allCases) { option in
                            Button {
                                viewModel.selectedSortOption = option
                            } label: {
                                HStack {
                                    Label(option.rawValue, systemImage: option.systemImage)
                                    if viewModel.selectedSortOption == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                }
            }
            .refreshable {
                viewModel.loadSubmissions()
            }
        }
    }
    
    private var isStatusFiltered: Bool {
        if case .all = viewModel.selectedStatusFilter {
            return false
        }
        return true
    }
    
    private func filterLabel(for filter: ReviewFilter) -> String {
        switch filter {
        case .all:
            return "All (\(viewModel.totalCount))"
        case .unreviewedOnly:
            return "Pending (\(viewModel.unreviewedCount(reviewStore: reviewStore)))"
        case .reviewedOnly:
            return "Reviewed (\(viewModel.reviewedCount(reviewStore: reviewStore)))"
        }
    }
    
    private var submissionListContent: some View {
        List {
            Section {
                ForEach(filteredList) { submission in
                    ZStack {
                        NavigationLink(destination: SubmissionDetailView(submission: submission)) {
                            EmptyView()
                        }
                        .opacity(0)
                        
                        SubmissionRowView(submission: submission)
                    }
                    .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button {
                            withAnimation {
                                reviewStore.toggleReview(for: submission)
                            }
                        } label: {
                            if reviewStore.isReviewed(submission) {
                                Label("Unreview", systemImage: "arrow.uturn.backward.circle")
                            } else {
                                Label("Review", systemImage: "checkmark.circle.fill")
                            }
                        }
                        .tint(reviewStore.isReviewed(submission) ? .orange : .green)
                    }
                }
            } header: {
                Text("\(filteredList.count) \(filteredList.count == 1 ? "submission" : "submissions")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
        }
        .listStyle(.plain)
        #if os(iOS)
        .background(Color(UIColor.systemGroupedBackground))
        #else
        .background(Color(NSColor.windowBackgroundColor))
        #endif
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Submissions Found")
                .font(.headline)
            
            Text(viewModel.searchText.isEmpty ? "No submissions match your active filter." : "No results for \"\(viewModel.searchText)\".")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            if !viewModel.searchText.isEmpty || isStatusFiltered || viewModel.selectedReviewFilter != .all {
                Button("Reset Filters") {
                    viewModel.searchText = ""
                    viewModel.selectedStatusFilter = .all
                    viewModel.selectedReviewFilter = .all
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorStateView(message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            Text("Unable to Load Submissions")
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button("Retry") {
                viewModel.loadSubmissions()
            }
            .buttonStyle(.borderedProminent)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
