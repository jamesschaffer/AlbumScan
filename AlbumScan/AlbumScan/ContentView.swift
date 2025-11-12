import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState()

    // Receive environment objects from App level (don't create new instances)
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var scanLimitManager: ScanLimitManager
    @EnvironmentObject var remoteConfigManager: RemoteConfigManager

    var body: some View {
        Group {
            if appState.cameraPermissionDenied {
                PermissionErrorView()
                    .environmentObject(appState)
            } else {
                CameraView()
                    .environmentObject(appState)
                    .environmentObject(subscriptionManager)
                    .environmentObject(scanLimitManager)
                    .environmentObject(remoteConfigManager)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
