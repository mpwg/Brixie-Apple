import SwiftUI

struct SetCardView: View {
    let set: LegoSet
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncCachedImage(url: set.imageURL) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 120)
            }
            .frame(height: 120)
            .accessibilityLabel("Image of LEGO set \(set.name)")
            
            Text(set.name)
                .font(.headline)
                .accessibilityIdentifier("setName")
            Text("Set #\(set.setNumber)")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .accessibilityIdentifier("setNumber")
            Text("Year: \(set.year)")
                .font(.caption)
                .accessibilityIdentifier("setYear")
            Text("Parts: \(set.numParts)")
                .font(.caption)
                .accessibilityIdentifier("setParts")
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
        .shadow(radius: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("LEGO set \(set.name), number \(set.setNumber), year \(set.year), \(set.numParts) parts")
    }
}

#Preview {
    SetCardView(set: LegoSet.example)
}
