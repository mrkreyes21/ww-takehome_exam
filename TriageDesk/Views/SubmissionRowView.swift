import SwiftUI

struct SubmissionRowView: View {
    let submission: Submission
    @EnvironmentObject private var reviewStore: ReviewStore
    
    private var isReviewed: Bool {
        reviewStore.isReviewed(submission)
    }
    
    private var currentStatus: SubmissionStatus {
        isReviewed ? .reviewed : submission.status
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                Text(currentStatus.capsuleTitle)
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(0.6)
                    .foregroundColor(.white)
                    .frame(width: 84)
                    .frame(maxHeight: .infinity)
                    .background(currentStatus.solidBadgeColor)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(submission.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if let email = submission.displayEmail {
                        Text(email)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    } else if let phone = submission.displayPhone {
                        Text(phone)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                .padding(.vertical, 10)
                
                Spacer(minLength: 4)
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(submission.formattedDate)
                        .font(.system(size: 12, weight: .semibold))
                        #if os(iOS)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        #else
                        .foregroundColor(Color(NSColor.secondaryLabelColor))
                        #endif
                    
                    Text(submission.formattedTime)
                        .font(.system(size: 11, weight: .regular))
                        #if os(iOS)
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                        #else
                        .foregroundColor(Color(NSColor.tertiaryLabelColor))
                        #endif
                }
                .padding(.vertical, 10)
                .padding(.trailing, 14)
            }
            .fixedSize(horizontal: false, vertical: true)
            #if os(iOS)
            .background(Color(UIColor.tertiarySystemGroupedBackground))
            #else
            .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
            #endif
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: submission.serviceIcon)
                            .font(.system(size: 11))
                        Text(submission.displayService)
                            .font(.caption.weight(.medium))
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Capsule())
                    
                    if let phone = submission.displayPhone, submission.displayEmail != nil {
                        HStack(spacing: 4) {
                            Image(systemName: "phone.fill")
                                .font(.system(size: 9))
                            Text(phone)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.secondary.opacity(0.08))
                        .clipShape(Capsule())
                    }
                    
                    Spacer()
                }
                
                if let message = submission.message?.trimmingCharacters(in: .whitespacesAndNewlines), !message.isEmpty {
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        }
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
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

struct StatusBadgeView: View {
    let status: SubmissionStatus
    var isSolid: Bool = true
    
    var body: some View {
        Text(status.capsuleTitle)
            .font(.system(size: 10, weight: .heavy, design: .rounded))
            .tracking(0.5)
            .foregroundColor(isSolid ? .white : status.tintColor)
            .frame(width: 84)
            .padding(.vertical, 5)
            .background(isSolid ? status.solidBadgeColor : status.tintColor.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
