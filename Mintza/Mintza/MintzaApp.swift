//
//  MintzaApp.swift
//  Mintza
//
//  Created by etudiant on 23/10/2026.
//

import SwiftUI
import GoogleSignIn
import CoreData

@main
struct MintzaApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { GIDSignIn.sharedInstance.handle($0) }
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
