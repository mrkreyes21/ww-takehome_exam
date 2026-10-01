import SwiftUI

struct SubmissionRowView: View {
    let submission: Submission
    @EnvironmentObject private var reviewStore: ReviewStore
    
    private var isReviewed: Bool {
        reviewStore.isReviewed(submission)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // header row: name, status badge, reviewed checkmark
            HStack(alignment: .center, spacing: 8) {
                if isReviewed {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.subheadline)
                }
                
                Text(submission.name)
                    .font(.headline)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // status pill
                StatusBadgeView(status: submission.status)
            }
            
            // middle row: service & formatted date
            HStack(spacing: 8) {
                Label(submission.displayService, systemImage: "tag.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Spacer()
                
                Label(submission.formattedDate, systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // preview of message if available
            if let message = submission.message?.trimmingCharacters(in: .whitespacesAndNewlines), !message.isEmpty {
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button {
                withAnimation {
                    reviewStore.toggleReview(for: submission)
                }
            } label: {
                if isReviewed {
                    Label("Unreview", systemImage: "arrow.uturn.backward.circle")
                } else {
                    Label("Review", systemImage: "checkmark.circle.fill")
                }
            }
            .tint(isReviewed ? .orange : .green)
        }
    }
}

struct StatusBadgeView: View {
    let status: SubmissionStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.systemImage)
                .font(.system(size: 9, weight: .bold))
            Text(status.displayName)
                .font(.caption2.weight(.semibold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(status.tintColor.opacity(0.15))
        .foregroundColor(status.tintColor)
        .clipShape(Capsule())
    }
}
