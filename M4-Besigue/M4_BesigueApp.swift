//
//  M4_BesigueApp.swift
//  M4-Besigue
//
//  Created by Paul Faustin on 6/22/25.
//

import SwiftUI

@main
struct M4_BesigueApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environment(\.audioManager, AudioManager.shared)
        }
    }
}
