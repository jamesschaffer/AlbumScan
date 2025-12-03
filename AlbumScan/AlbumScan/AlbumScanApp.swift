import SwiftUI
import CoreData
import UIKit
import FirebaseCore
import FirebaseAppCheck

// MARK: - Custom App Check Provider Factory
// This is the official recommended approach from Firebase documentation.
// We implement AppCheckProviderFactory protocol instead of using the convenience
// classes (AppAttestProviderFactory) which may not be available in all build configs.

class AlbumScanAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> (any AppCheckProvider)? {
        #if DEBUG
        // Use debug provider during development
        // This generates debug tokens that must be registered in Firebase Console
        let provider = AppCheckDebugProvider(app: app)
        if let token = provider?.localDebugToken() {
            print("🔐 [AppCheck] Debug token: \(token)")
        }
        return provider
        #else
        // Use App Attest in production (iOS 14+)
        // Falls back to DeviceCheck for older iOS versions
        if #available(iOS 14.0, *) {
            return AppAttestProvider(app: app)
        } else {
            return DeviceCheckProvider(app: app)
        }
        #endif
    }
}

@main
struct AlbumScanApp: App {
    let persistenceController = PersistenceController.shared
    @State private var showingSplash = true

    // Subscription & Limit Managers
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var scanLimitManager = ScanLimitManager.shared
    @StateObject private var remoteConfigManager = RemoteConfigManager.shared

    init() {
        // Configure App Check BEFORE Firebase.configure()
        // This enables device attestation for Cloud Functions calls
        let providerFactory = AlbumScanAppCheckProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)

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
