//
//  AppState.swift
//  TaskFlowiOS
//
//  Created by stone on 2025/7/22.
//

// Shared application state for tab selection and pomodoro launch

import SwiftUI
import SwiftData

/// Global app state for selected tab and pomodoro launch
final class AppState: ObservableObject {
    enum Tab: Int {
        case plans, tasks, pomodoro, stats, settings
    }

    @Published var selectedTab: Tab = .plans
    @Published var startingPomodoro: STPomodoro?
    @Published var currentPomodoro: STPomodoro?
    @Published var isCurrentPomodoroRunning: Bool = false
    @Published var selectTask: STTask?
    @Published var setting: STAppSetting?
}
