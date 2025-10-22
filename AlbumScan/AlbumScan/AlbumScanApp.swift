import SwiftUI
import CoreData
import UIKit

@main
struct AlbumScanApp: App {
    let persistenceController = PersistenceController.shared
    @State private var showingSplash = true

    init() {
        // Debug: Print all available fonts
        print("\n🔤 === AVAILABLE FONTS ===")
        for family in UIFont.familyNames.sorted() {
            print("Family: \(family)")
            for name in UIFont.fontNames(forFamilyName: family) {
                print("  → \(name)")
            }
        }
        print("=========================\n")
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)

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
