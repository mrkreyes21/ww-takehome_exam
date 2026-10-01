import SwiftUI

struct DashboardSummaryView: View {
    @ObservedObject var viewModel: SubmissionListViewModel
    @EnvironmentObject private var reviewStore: ReviewStore
    
    private var currentDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date()).uppercased()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // header date and title
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(currentDateString)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                        .tracking(0.6)
                    
                    HStack(spacing: 5) {
                        Text("Triage")
                            .font(.title3.weight(.regular))
                        Text("Dashboard")
                            .font(.title3.weight(.bold))
                    }
                }
                
                Spacer()
                
                // unreviewed action badge
                let unreviewed = viewModel.unreviewedCount(reviewStore: reviewStore)
                if unreviewed > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10))
                        Text("\(unreviewed) ACTION REQUIRED")
                            .font(.system(size: 10, weight: .heavy))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(red: 0.95, green: 0.45, blue: 0.20))
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 2)
            
            // distribution graph and status filters
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("QUEUE STATUS DISTRIBUTION")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                            .tracking(0.5)
                        
                        if case .status(let activeStatus) = viewModel.selectedStatusFilter {
                            HStack(spacing: 4) {
                                Text("Filtered by")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                Text(activeStatus.displayName)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(activeStatus.solidBadgeColor)
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        viewModel.selectedStatusFilter = .all
                                    }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                            }
                        } else {
                            Text("\(viewModel.totalCount) submissions • \(viewModel.unreviewedCount(reviewStore: reviewStore)) pending")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // review state filter switcher
                    HStack(spacing: 2) {
                        triageSegmentButton(title: "All", filter: .all)
                        triageSegmentButton(title: "Pending", filter: .unreviewedOnly)
                        triageSegmentButton(title: "Done", filter: .reviewedOnly)
                    }
                    .padding(2)
                    #if os(iOS)
                    .background(Color(UIColor.tertiarySystemGroupedBackground))
                    #else
                    .background(Color.primary.opacity(0.06))
                    #endif
                    .clipShape(Capsule())
                }
                
                // proportional status bar
                ProportionalStatusBar(
                    statuses: SubmissionStatus.allCases,
                    viewModel: viewModel,
                    reviewStore: reviewStore
                )
                
                // status filter pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterPill(
                            title: "All",
                            count: viewModel.totalCount,
                            icon: "tray.fill",
                            color: .blue,
                            isSelected: viewModel.selectedStatusFilter == .all && viewModel.selectedReviewFilter == .all
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.selectedStatusFilter = .all
                                viewModel.selectedReviewFilter = .all
                            }
                        }
                        
                        ForEach(SubmissionStatus.allCases, id: \.self) { status in
                            let count = viewModel.statusCount(for: status, reviewStore: reviewStore)
                            let isSelected: Bool = {
                                if case .status(let selected) = viewModel.selectedStatusFilter, selected == status {
                                    return true
                                }
                                return false
                            }()
                            
                            FilterPill(
                                title: status.displayName,
                                count: count,
                                icon: status.systemImage,
                                color: status.solidBadgeColor,
                                isSelected: isSelected
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    if isSelected {
                                        viewModel.selectedStatusFilter = .all
                                    } else {
                                        viewModel.selectedStatusFilter = .status(status)
                                        viewModel.selectedReviewFilter = .all
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .padding(12)
            #if os(iOS)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            #else
            .background(Color(NSColor.controlBackgroundColor))
            #endif
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
        }
        .padding(.bottom, 4)
    }
    
    @ViewBuilder
    private func triageSegmentButton(title: String, filter: ReviewFilter) -> some View {
        let isSelected = viewModel.selectedReviewFilter == filter && viewModel.selectedStatusFilter == .all
        Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                viewModel.selectedReviewFilter = filter
                viewModel.selectedStatusFilter = .all
            }
        } label: {
            Text(title)
                .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .white : .secondary)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(
                    isSelected ? Color.primary.opacity(0.85) : Color.clear
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct ProportionalStatusBar: View {
    let statuses: [SubmissionStatus]
    @ObservedObject var viewModel: SubmissionListViewModel
    let reviewStore: ReviewStore
    
    var body: some View {
        GeometryReader { geometry in
            let total = max(viewModel.totalCount, 1)
            let activeStatuses = statuses.filter { viewModel.statusCount(for: $0, reviewStore: reviewStore) > 0 }
            
            HStack(spacing: 2.5) {
                ForEach(activeStatuses, id: \.self) { status in
                    let count = viewModel.statusCount(for: status, reviewStore: reviewStore)
                    let ratio = CGFloat(count) / CGFloat(total)
                    let width = max((geometry.size.width - CGFloat(max(activeStatuses.count - 1, 0)) * 2.5) * ratio, 6)
                    
                    let isSelected: Bool = {
                        if case .status(let selected) = viewModel.selectedStatusFilter, selected == status {
                            return true
                        }
                        return false
                    }()
                    
                    let isDimmed: Bool = {
                        if case .status(let selected) = viewModel.selectedStatusFilter, selected != status {
                            return true
                        }
                        return false
                    }()
                    
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if isSelected {
                                viewModel.selectedStatusFilter = .all
                            } else {
                                viewModel.selectedStatusFilter = .status(status)
                                viewModel.selectedReviewFilter = .all
                            }
                        }
                    } label: {
                        Rectangle()
                            .fill(status.solidBadgeColor.opacity(isDimmed ? 0.3 : 1.0))
                            .frame(width: width, height: 10)
                    }
                    .buttonStyle(.plain)
                }
            }
            .clipShape(Capsule())
        }
        .frame(height: 10)
    }
}

private struct FilterPill: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.white.opacity(0.3) : color)
                        .frame(width: 18, height: 18)
                    
                    Image(systemName: icon)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .bold : .semibold))
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text("\(count)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected ? .white.opacity(0.95) : .secondary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(
                        isSelected ? Color.white.opacity(0.25) : Color.primary.opacity(0.06)
                    )
                    .clipShape(Capsule())
            }
            .padding(.leading, 5)
            .padding(.trailing, 7)
            .padding(.vertical, 5)
            .background(
                isSelected ? color : Color.secondary.opacity(0.09)
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? color : Color.primary.opacity(0.06), lineWidth: 1)
            )
            .shadow(color: isSelected ? color.opacity(0.25) : Color.clear, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}
