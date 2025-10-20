import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // App branding
            VStack(spacing: 16) {
                Image(systemName: "record.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)

                Text("AlbumScan")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Discover music that matters")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Get Started button
            Button(action: {
                appState.requestCameraPermission()
            }) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
            .environmentObject(AppState())
    }
}
