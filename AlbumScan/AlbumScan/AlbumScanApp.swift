import SwiftUI
import CoreData
import UIKit

@main
struct AlbumScanApp: App {
    let persistenceController = PersistenceController.shared
    @State private var showingSplash = true


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
