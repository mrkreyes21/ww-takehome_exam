import SwiftUI

struct SubmissionRowView: View {
    let submission: Submission
    var duplicateMatch: DuplicateMatch? = nil
    @EnvironmentObject private var reviewStore: ReviewStore
    
    private var isReviewed: Bool {
        reviewStore.isReviewed(submission)
    }
    
    private var currentStatus: SubmissionStatus {
        submission.effectiveStatus(in: reviewStore)
    }
    
    private var accessibilityDescription: String {
        var description = "\(submission.name), status \(currentStatus.displayName), submitted \(submission.formattedDate) at \(submission.formattedTime). Service: \(submission.displayService)."
        if let email = submission.displayEmail {
            description += " Email: \(email)."
        }
        if let phone = submission.displayPhone {
            description += " Phone: \(phone)."
        }
        if let duplicate = duplicateMatch {
            description += " Warning: Potential duplicate submission (\(duplicate.reason))."
        }
        return description
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // top header bar with status badge, sender info, and timestamp
            HStack(alignment: .center, spacing: 10) {
                Text(currentStatus.capsuleTitle)
                    .font(.caption2.weight(.heavy))
                    .tracking(0.6)
                    .foregroundColor(.white)
                    .frame(width: 84)
                    .frame(maxHeight: .infinity)
                    .background(currentStatus.solidBadgeColor)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .accessibilityLabel("Status: \(currentStatus.displayName)")
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(submission.name)
                        .font(.headline)
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
                        .font(.caption.weight(.semibold))
                        #if os(iOS)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        #else
                        .foregroundColor(Color(NSColor.secondaryLabelColor))
                        #endif
                    
                    Text(submission.formattedTime)
                        .font(.caption2)
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
            
            // bottom body with service tag, phone, duplicate chip, and message preview
            VStack(alignment: .leading, spacing: 10) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        // service category tag
                        HStack(spacing: 4) {
                            Image(systemName: submission.serviceIcon)
                                .font(.caption2)
                            Text(submission.displayService)
                                .font(.caption.weight(.medium))
                                .lineLimit(1)
                        }
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Capsule())
                        
                        // optional phone chip (single line guaranteed)
                        if let phone = submission.displayPhone, submission.displayEmail != nil {
                            HStack(spacing: 4) {
                                Image(systemName: "phone.fill")
                                    .font(.system(size: 9))
                                Text(phone)
                                    .font(.caption)
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                            }
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.secondary.opacity(0.08))
                            .clipShape(Capsule())
                        }
                        
                        // lightweight duplicate badge (single line guaranteed)
                        if let duplicate = duplicateMatch {
                            HStack(spacing: 3) {
                                Image(systemName: "doc.on.doc.fill")
                                    .font(.system(size: 8))
                                Text("\(duplicate.matchingCount)x")
                                    .font(.caption2.weight(.bold))
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                            }
                            .foregroundColor(Color(red: 0.90, green: 0.50, blue: 0.15))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color(red: 0.90, green: 0.50, blue: 0.15).opacity(0.12))
                            .clipShape(Capsule())
                        }
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
                
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
                .stroke(duplicateMatch != nil ? Color.orange.opacity(0.35) : Color.primary.opacity(0.08), lineWidth: duplicateMatch != nil ? 1.5 : 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint("Double tap to view full submission details.")
    }
}

struct StatusBadgeView: View {
    let status: SubmissionStatus
    var isSolid: Bool = true
    
    var body: some View {
        Text(status.capsuleTitle)
            .font(.caption2.weight(.heavy))
            .tracking(0.5)
            .foregroundColor(isSolid ? .white : status.tintColor)
            .frame(width: 84)
            .padding(.vertical, 5)
            .background(isSolid ? status.solidBadgeColor : status.tintColor.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .accessibilityLabel("Status: \(status.displayName)")
    }
}
