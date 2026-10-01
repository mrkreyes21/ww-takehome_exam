import SwiftUI

struct SubmissionTableView: View {
    let submissions: [Submission]
    @EnvironmentObject private var reviewStore: ReviewStore
    
    var body: some View {
        ScrollView([.horizontal, .vertical], showsIndicators: true) {
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                Section(header: tableHeader) {
                    ForEach(Array(submissions.enumerated()), id: \.element.id) { index, submission in
                        tableRow(for: submission, isEven: index.isMultiple(of: 2))
                    }
                }
            }
            .padding(.bottom, 32)
        }
        #if os(iOS)
        .background(Color(UIColor.systemGroupedBackground))
        #else
        .background(Color(NSColor.windowBackgroundColor))
        #endif
    }
    
    private var tableHeader: some View {
        HStack(spacing: 0) {
            headerCell("Action", width: 65, alignment: .center)
            headerCell("Status", width: 115, alignment: .leading)
            headerCell("Sender Name", width: 160, alignment: .leading)
            headerCell("Phone", width: 145, alignment: .leading)
            headerCell("Email", width: 185, alignment: .leading)
            headerCell("Service", width: 150, alignment: .leading)
            headerCell("Submitted", width: 125, alignment: .leading)
            headerCell("Record ID", width: 85, alignment: .leading)
            headerCell("Version", width: 75, alignment: .center)
        }
        .padding(.vertical, 10)
        #if os(iOS)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        #else
        .background(Color(NSColor.controlBackgroundColor))
        #endif
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.secondary.opacity(0.25)),
            alignment: .bottom
        )
    }
    
    private func headerCell(_ title: String, width: CGFloat, alignment: Alignment) -> some View {
        Text(title)
            .font(.caption.weight(.bold))
            .foregroundColor(.secondary)
            .textCase(.uppercase)
            .frame(width: width, alignment: alignment)
            .padding(.horizontal, 8)
    }
    
    private func tableRow(for submission: Submission, isEven: Bool) -> some View {
        let isReviewed = reviewStore.isReviewed(submission)
        
        return NavigationLink(destination: SubmissionDetailView(submission: submission)) {
            HStack(spacing: 0) {
                // review toggle
                Button {
                    withAnimation {
                        reviewStore.toggleReview(for: submission)
                    }
                } label: {
                    Image(systemName: isReviewed ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18))
                        .foregroundColor(isReviewed ? .green : .secondary.opacity(0.5))
                }
                .buttonStyle(.plain)
                .frame(width: 65, alignment: .center)
                .padding(.horizontal, 8)
                
                // status badge
                HStack {
                    let currentStatus = isReviewed ? SubmissionStatus.reviewed : submission.status
                    StatusBadgeView(status: currentStatus)
                }
                .frame(width: 115, alignment: .leading)
                .padding(.horizontal, 8)
                
                // sender name
                Text(submission.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .frame(width: 160, alignment: .leading)
                    .padding(.horizontal, 8)
                
                // phone
                Text(submission.phone ?? "—")
                    .font(.caption)
                    .foregroundColor(submission.phone != nil ? .primary : .secondary)
                    .lineLimit(1)
                    .frame(width: 145, alignment: .leading)
                    .padding(.horizontal, 8)
                
                // email
                Text(submission.displayEmail ?? "—")
                    .font(.caption)
                    .foregroundColor(submission.displayEmail != nil ? .blue : .secondary)
                    .lineLimit(1)
                    .frame(width: 185, alignment: .leading)
                    .padding(.horizontal, 8)
                
                // service
                Text(submission.displayService)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .frame(width: 150, alignment: .leading)
                    .padding(.horizontal, 8)
                
                // date
                Text(submission.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .frame(width: 125, alignment: .leading)
                    .padding(.horizontal, 8)
                
                // remote id
                Text(submission.remoteId ?? "—")
                    .font(.caption.monospaced())
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .frame(width: 85, alignment: .leading)
                    .padding(.horizontal, 8)
                
                // version
                Text(submission.displayFormVersion)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .frame(width: 75, alignment: .center)
                    .padding(.horizontal, 8)
            }
            .padding(.vertical, 8)
            .background(rowBackground(isEven: isEven))
            .overlay(
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color.secondary.opacity(0.12)),
                alignment: .bottom
            )
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func rowBackground(isEven: Bool) -> some View {
        #if os(iOS)
        if isEven {
            Color(UIColor.systemBackground)
        } else {
            Color(UIColor.secondarySystemBackground).opacity(0.6)
        }
        #else
        if isEven {
            Color(NSColor.controlBackgroundColor)
        } else {
            Color(NSColor.controlBackgroundColor).opacity(0.6)
        }
        #endif
    }
}
