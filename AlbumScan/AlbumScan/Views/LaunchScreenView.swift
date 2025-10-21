import SwiftUI

struct LaunchScreenView: View {
    let brandGreen = Color(red: 0, green: 0.87, blue: 0.32)

    var body: some View {
        ZStack {
            // Black background
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 26) {
                // Logo image
                Image("album-scan-logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 318, height: 138)

                // Tagline
                VStack(spacing: 0) {
                    Text("Scan. Learn.")
                        .font(
                            Font.custom("Helvetica Neue", size: 32)
                                .weight(.bold)
                        )
                        .foregroundColor(.white)

                    Text("Collect.")
                        .font(
                            Font.custom("Helvetica Neue", size: 32)
                                .weight(.bold)
                        )
                        .foregroundColor(.white)
                }
            }
        }
    }
}

struct LaunchScreenView_Previews: PreviewProvider {
    static var previews: some View {
        LaunchScreenView()
    }
}
