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
                if viewModel.isLoading {
                    ProgressView("Loading submissions...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = viewModel.errorMessage {
                    errorStateView(message: errorMessage)
                } else {
                    if viewModel.layoutMode == .list {
                        submissionListContent
                    } else {
                        submissionTableContent
                    }
                }
            }
            .navigationTitle("Triage Desk")
            .searchable(text: $viewModel.searchText, prompt: "Search by name, email, or message...")
            .toolbar {
                // layout mode toggle
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.layoutMode = (viewModel.layoutMode == .list ? .table : .list)
                        }
                    } label: {
                        Image(systemName: viewModel.layoutMode == .list ? "tablecells" : "list.bullet")
                    }
                    .accessibilityLabel(viewModel.layoutMode == .list ? "Switch to Table View" : "Switch to List View")
                    .accessibilityHint("Changes the submissions layout between list and spreadsheet table modes")
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
                    .accessibilityLabel("Filter by status")
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
                    .accessibilityLabel("Sort options")
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
    
    private var submissionListContent: some View {
        List {
            // dashboard summary
            Section {
                DashboardSummaryView(viewModel: viewModel)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 0, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            
            // queue entries
            if filteredList.isEmpty {
                Section {
                    emptyStateView
                        .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 20, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
            } else {
                Section {
                    ForEach(filteredList) { submission in
                        ZStack {
                            NavigationLink(destination: SubmissionDetailView(submission: submission, allSubmissions: viewModel.submissions)) {
                                EmptyView()
                            }
                            .opacity(0)
                            
                            SubmissionRowView(
                                submission: submission,
                                duplicateMatch: viewModel.duplicateMatch(for: submission)
                            )
                        }
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
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
                            .accessibilityLabel(reviewStore.isReviewed(submission) ? "Mark as unreviewed" : "Mark as reviewed")
                        }
                    }
                } header: {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Queue Entries")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("\(filteredList.count) \(filteredList.count == 1 ? "record" : "records") ready for triage")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if isStatusFiltered || viewModel.selectedReviewFilter != .all || !viewModel.searchText.isEmpty {
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.selectedStatusFilter = .all
                                    viewModel.selectedReviewFilter = .all
                                    viewModel.searchText = ""
                                }
                            } label: {
                                Text("Clear Filter")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.blue)
                            }
                            .accessibilityLabel("Clear active filter")
                        } else {
                            Text("\(filteredList.count) TOTAL")
                                .font(.caption.weight(.heavy))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.top, 0)
                    .padding(.bottom, 2)
                }
            }
        }
        .listStyle(.plain)
        #if os(iOS)
        .background(Color(UIColor.systemGroupedBackground))
        #else
        .background(Color(NSColor.windowBackgroundColor))
        #endif
    }
    
    private var submissionTableContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                DashboardSummaryView(viewModel: viewModel)
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                
                if filteredList.isEmpty {
                    emptyStateView
                        .padding(.top, 24)
                } else {
                    SubmissionTableView(submissions: filteredList)
                }
            }
        }
        #if os(iOS)
        .background(Color(UIColor.systemGroupedBackground))
        #else
        .background(Color(NSColor.windowBackgroundColor))
        #endif
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 14) {
            Image(systemName: "tray")
                .font(.system(size: 44))
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
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.searchText = ""
                        viewModel.selectedStatusFilter = .all
                        viewModel.selectedReviewFilter = .all
                    }
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Reset all filters")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
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
            .accessibilityLabel("Retry loading submissions")
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
