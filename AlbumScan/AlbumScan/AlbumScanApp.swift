import SwiftUI
import CoreData
import UIKit
import FirebaseCore

@main
struct AlbumScanApp: App {
    let persistenceController = PersistenceController.shared
    @State private var showingSplash = true

    // Subscription & Limit Managers
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var scanLimitManager = ScanLimitManager.shared
    @StateObject private var remoteConfigManager = RemoteConfigManager.shared

    init() {
        // Configure Firebase
        FirebaseApp.configure()

        // Initialize Firebase Remote Config
        RemoteConfigManager.shared.initialize()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environmentObject(subscriptionManager)
                    .environmentObject(scanLimitManager)
                    .environmentObject(remoteConfigManager)

                if showingSplash {
                    LaunchScreenView()
                        .transition(.opacity.animation(.easeOut(duration: 0.5)))
                        .zIndex(1)
                }
            }
            .onAppear {
                // Show splash for 1.5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    showingSplash = false
                }
            }
        }
    }
}
