import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState()

    var body: some View {
        Group {
            if appState.isFirstLaunch {
                WelcomeView()
                    .environmentObject(appState)
            } else if appState.cameraPermissionDenied {
                PermissionErrorView()
                    .environmentObject(appState)
            } else {
                CameraView()
                    .environmentObject(appState)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
