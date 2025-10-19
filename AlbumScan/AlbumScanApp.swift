//
//  AlbumScanApp.swift
//  AlbumScan
//
//  Created by James Schaffer on 10/19/25.
//

import SwiftUI
import CoreData

@main
struct AlbumScanApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
