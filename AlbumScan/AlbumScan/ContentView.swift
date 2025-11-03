import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState()
    @StateObject private var subscriptionManager = SubscriptionManager.shared

    var body: some View {
        Group {
            if appState.cameraPermissionDenied {
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
