//
//  TaskFlowiOSApp.swift
//  TaskFlowiOS
//
//  Created by stone on 2025/7/14.
//

import SwiftUI
import SwiftData

@main
struct TaskFlowiOSApp: App {
    // Shared SwiftData container
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            STPlan.self,
            STTask.self,
            STAppSetting.self,
            STPomodoro.self,
            STHistory.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    // AppState instance to drive tab selection and pomodoro launching
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(appState)
        }
        .modelContainer(sharedModelContainer)
    }
}
