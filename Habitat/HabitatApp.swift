//
//  HabitatApp.swift
//  Habitat
//
//  Created by Alexander Saw on 02/02/2026.
//

import SwiftUI
import SwiftData

@main
struct HabitatApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Habit.self,
            HabitGroup.self,
            DailyLog.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        // Request notification permission on app launch
        Task {
            _ = await NotificationService.shared.requestPermission()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
