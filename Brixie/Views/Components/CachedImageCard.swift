import SwiftUI

struct CachedImageCard<Content: View>: View {
    let urlString: String?
    let maxHeight: CGFloat?
    let content: () -> Content

    init(
        urlString: String?,
        maxHeight: CGFloat? = nil,
        @ViewBuilder content: @escaping () -> Content = { EmptyView() }
    ) {
        self.urlString = urlString
        self.maxHeight = maxHeight
        self.content = content
    }

    var body: some View {
        VStack {
            AsyncCachedImage(urlString: urlString)
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: maxHeight)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                )

            content()
        }
    }
}

struct CachedImageCard_Previews: PreviewProvider {
    static var previews: some View {
        CachedImageCard(urlString: nil, maxHeight: 120) {
            Text("Caption")
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
