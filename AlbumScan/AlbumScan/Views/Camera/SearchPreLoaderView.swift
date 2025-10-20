import SwiftUI

struct SearchPreLoaderView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)

                Text("Identifying album...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(40)
            .background(Color.black.opacity(0.8))
            .cornerRadius(16)
        }
    }
}

struct SearchPreLoaderView_Previews: PreviewProvider {
    static var previews: some View {
        SearchPreLoaderView()
    }
}
