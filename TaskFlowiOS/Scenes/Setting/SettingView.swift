//
//  SettingView.swift
//  TaskFlowiOS
//
//  Created by stone on 2025/7/21.
//

import SwiftUI
import SwiftData

struct SettingView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var appState: AppState
    
    @Query private var settings: [STAppSetting]
    @State private var localSetting: STAppSetting?
    
    var body: some View {
        NavigationStack {
            Form {
                if let setting = localSetting {
                    Section(header: Text("Pomodoro Timer")) {
                        Stepper("Work Minutes: \(setting.pomodoroWorkMinutes)", value: Binding(
                            get: { setting.pomodoroWorkMinutes },
                            set: { localSetting?.pomodoroWorkMinutes = $0 }
                        ), in: 3...45)
                        
                        Stepper("Relax Minutes: \(setting.pomodoroRelaxMinutes)", value: Binding(
                            get: { setting.pomodoroRelaxMinutes },
                            set: { localSetting?.pomodoroRelaxMinutes = $0 }
                        ), in: 1...5)
                    }
                    
                    Section(header: Text("Review Notification")) {
                        Toggle("Enable Notification", isOn: Binding(
                            get: { setting.enableReviewNotification },
                            set: { localSetting?.enableReviewNotification = $0 }
                        ))
                        
                        DatePicker("Notification Time",
                                   selection: Binding(
                                    get: { setting.reviewNotificationTime },
                                    set: { localSetting?.reviewNotificationTime = $0 }
                                   ),
                                   displayedComponents: [.hourAndMinute])
                        .disabled(!setting.enableReviewNotification)
                        .opacity(setting.enableReviewNotification ? 1.0 : 0.5)
                    }
                } else {
                    ProgressView("Loading settings...")
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                if let existing = settings.first {
                    localSetting = existing
                    appState.setting = existing // ✅ sync to AppState
                } else {
                    let newSetting = STAppSetting()
                    context.insert(newSetting)
                    try? context.save()
                    localSetting = newSetting
                    appState.setting = newSetting // ✅ sync to AppState
                }
            }
            .onDisappear {
                if let setting = localSetting {
                    try? context.save()
                    appState.setting = setting // ✅ re-sync in case of changes
                }
            }
        }
    }
}

#Preview {
    // In-memory container for preview
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let previewContainer = try! ModelContainer(
        for: STAppSetting.self,
        configurations: config
    )
    
    // Optional: insert a sample setting for preview
    let sampleSetting = STAppSetting(
        pomodoroWorkMinutes: 25,
        pomodoroRelaxMinutes: 5,
        enableReviewNotification: true,
        reviewNotificationTime: Calendar.current.date(bySettingHour: 18, minute: 15, second: 0, of: Date())!
    )
    do {
        previewContainer.mainContext.insert(sampleSetting)
    }
    
    // Provide an AppState with the preview setting
    let appState = AppState()
    appState.setting = sampleSetting
    
    return SettingView()
        .environmentObject(appState)
        .modelContainer(previewContainer)
}
