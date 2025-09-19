import SwiftUI

struct SetDetailView: View {
    let set: LegoSet
    @State private var showShareSheet = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                AsyncCachedImage(url: set.imageURL) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 200)
                }
                .frame(height: 200)
                .accessibilityLabel("Image of LEGO set \(set.name)")
                
                Text(set.name)
                    .font(.title)
                    .accessibilityIdentifier("setDetailName")
                Text("Set #\(set.setNumber)")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .accessibilityIdentifier("setDetailNumber")
                Text("Year: \(set.year)")
                    .font(.subheadline)
                    .accessibilityIdentifier("setDetailYear")
                Text("Parts: \(set.numParts)")
                    .font(.subheadline)
                    .accessibilityIdentifier("setDetailParts")
                
                if let gallery = set.imageGallery, !gallery.isEmpty {
                    Text("Gallery")
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(gallery, id: \.self) { url in
                                AsyncCachedImage(url: url) {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 120, height: 120)
                                }
                                .frame(width: 120, height: 120)
                                .accessibilityLabel("Gallery image for \(set.name)")
                            }
                        }
                    }
                    .accessibilityIdentifier("setGallery")
                }
                
                Button(action: { showShareSheet = true }) {
                    Label("Share Set", systemImage: "square.and.arrow.up")
                }
                .accessibilityIdentifier("shareButton")
                .sheet(isPresented: $showShareSheet) {
                    ActivityView(activityItems: [shareText])
                }
            }
            .padding()
        }
        .accessibilityElement(children: .contain)
    }
    
    private var shareText: String {
        "Check out LEGO set \(set.name) (#\(set.setNumber)), released in \(set.year) with \(set.numParts) parts!"
    }
}

#Preview {
    SetDetailView(set: LegoSet.example)
}

// UIKit share sheet wrapper for SwiftUI
import UIKit
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
