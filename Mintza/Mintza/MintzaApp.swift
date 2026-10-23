//
//  MintzaApp.swift
//  Mintza
//
//  Created by etudiant on 23/10/2026.
//

import SwiftUI
import CoreData

@main
struct MintzaApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
