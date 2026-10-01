
import SwiftUI

struct SubmissionDetailView: View {
    let submission: Submission
    @EnvironmentObject private var reviewStore: ReviewStore
    
    private var isReviewed: Bool {
        reviewStore.isReviewed(submission)
    }
    
    var body: some View {
        List {
            // Status & Triage Action Banner
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(submission.name)
                                .font(.title2.bold())
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 8) {
                                StatusBadgeView(status: submission.status)
                                
                                if isReviewed {
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle.fill")
                                        Text("Reviewed")
                                    }
                                    .font(.caption2.weight(.semibold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.green.opacity(0.15))
                                    .foregroundColor(.green)
                                    .clipShape(Capsule())
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    
                    Divider()
                    
                    Button {
                        withAnimation {
                            reviewStore.toggleReview(for: submission)
                        }
                    } label: {
                        HStack {
                            Image(systemName: isReviewed ? "arrow.uturn.backward.circle.fill" : "checkmark.seal.fill")
                            Text(isReviewed ? "Mark as Unreviewed" : "Mark as Reviewed")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(isReviewed ? .orange : .green)
                }
                .padding(.vertical, 4)
            }
            
            // Message / Request Content
            Section(header: Text("Inquiry Message")) {
                if let message = submission.message?.trimmingCharacters(in: .whitespacesAndNewlines), !message.isEmpty {
                    Text(message)
                        .font(.body)
                        .textSelection(.enabled)
                        .padding(.vertical, 4)
                } else {
                    Text("No message provided with this submission.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .italic()
                        .padding(.vertical, 4)
                }
            }
            
            // Contact Information
            Section(header: Text("Contact Details")) {
                if let email = submission.displayEmail {
                    HStack {
                        Label("Email", systemImage: "envelope.fill")
                            .foregroundColor(.secondary)
                        Spacer()
                        if let emailUrl = URL(string: "mailto:\(email)") {
                            Link(email, destination: emailUrl)
                                .font(.subheadline)
                        } else {
                            Text(email)
                                .font(.subheadline)
                                .textSelection(.enabled)
                        }
                    }
                }
                
                if let phone = submission.displayPhone {
                    HStack {
                        Label("Phone", systemImage: "phone.fill")
                            .foregroundColor(.secondary)
                        Spacer()
                        let cleanPhone = phone.filter { "0123456789+".contains($0) }
                        if let phoneUrl = URL(string: "tel:\(cleanPhone)") {
                            Link(phone, destination: phoneUrl)
                                .font(.subheadline)
                        } else {
                            Text(phone)
                                .font(.subheadline)
                                .textSelection(.enabled)
                        }
                    }
                }
                
                if submission.displayEmail == nil && submission.displayPhone == nil {
                    Text("No contact information provided.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            
            // Service & Form Metadata
            Section(header: Text("Submission Metadata")) {
                HStack {
                    Label("Requested Service", systemImage: submission.serviceIcon)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(submission.displayService)
                        .font(.subheadline.weight(.medium))
                }
                
                HStack {
                    Label("Date Submitted", systemImage: "calendar")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(submission.formattedFullDate)
                        .font(.subheadline)
                }
                
                HStack {
                    Label("Remote Record ID", systemImage: "number")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(submission.remoteId ?? "None")
                        .font(.subheadline.monospaced())
                        .foregroundColor(submission.remoteId != nil ? .primary : .secondary)
                }
                
                HStack {
                    Label("Form Version", systemImage: "doc.text")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(submission.displayFormVersion)
                        .font(.subheadline)
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        .navigationBarTitleDisplayMode(.inline)
        #else
        .listStyle(.inset)
        #endif
        .navigationTitle("Submission Details")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    withAnimation {
                        reviewStore.toggleReview(for: submission)
                    }
                } label: {
                    Image(systemName: isReviewed ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isReviewed ? .green : .secondary)
                }
                .accessibilityLabel(isReviewed ? "Mark as unreviewed" : "Mark as reviewed")
            }
        }
    }
}
