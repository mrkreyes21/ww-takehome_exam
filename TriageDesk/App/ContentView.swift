import SwiftUI

struct ContentView: View {
    @StateObject private var reviewStore = ReviewStore()
    
    var body: some View {
        SubmissionListView()
            .environmentObject(reviewStore)
    }
}

#Preview {
    ContentView()
}
