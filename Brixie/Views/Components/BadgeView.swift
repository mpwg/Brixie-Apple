import SwiftUI

struct BadgeView: View {
    let count: Int
    let color: Color

    var body: some View {
        Text("\(count)")
            .font(.caption2)
            .padding(6)
            .background(Capsule().fill(color))
            .foregroundColor(.white)
            .accessibilityLabel("\(count) missing items")
    }
}

#Preview {
    BadgeView(count: 3, color: .orange)
}
