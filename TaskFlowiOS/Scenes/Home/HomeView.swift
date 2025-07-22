//
//  HomeView.swift
//  TaskFlowiOS
//
//  Created by stone on 2025/7/14.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var context
    @Query private var plans: [STPlan]
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            PlanListView()
                .tabItem { Label("Plans", systemImage: "calendar") }
                .tag(AppState.Tab.plans)
            
            TaskListView()
                .tabItem { Label("Tasks", systemImage: "checkmark.square") }
                .tag(AppState.Tab.tasks)
            
            PomodoroView()
                .tabItem { Label("Pomodoro", systemImage: "timer") }
                .tag(AppState.Tab.pomodoro)
            
            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.xaxis") }
                .tag(AppState.Tab.stats)
            
            SettingView()
                .tabItem { Label("Settings", systemImage: "gear") }
                .tag(AppState.Tab.settings)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            tryToUpdateData()
        }
        .onAppear {
            tryToUpdateData()
        }
    }
    
    private func tryToUpdateData() {
        Task {
            updatePlansIfNeeded()
            await generateTodayTasksIfNeeded()
            await loadAppSettingToAppState()
        }
    }
    
    private func updatePlansIfNeeded() {
        let today = Calendar.current.startOfDay(for: .now)
        for plan in plans where plan.status == .notStarted {
            let start = Calendar.current.startOfDay(for: plan.startTime)
            let end = plan.estimatedEndTime.map { Calendar.current.startOfDay(for: $0) } ?? start
            if (start...end).contains(today) {
                plan.setInProgress()
            }
        }
        try? context.save()
    }
    
    private func generateTodayTasksIfNeeded() async {
        let today = Calendar.current.startOfDay(for: Date.now)
        
        // Check if there's already a history record for today
        let historyFetch = FetchDescriptor<STHistory>(
            predicate: #Predicate { $0.date == today },
            sortBy: []
        )
        let histories = try? context.fetch(historyFetch)
        guard histories?.isEmpty ?? true else {
            return // Already generated
        }
        
        // Filter active plans
        let activePlans = plans.filter { plan in
            plan.status != .finished && plan.status != .abandoned
        }
        
        for plan in activePlans {
            let start = Calendar.current.startOfDay(for: plan.startTime)
            let end = Calendar.current.startOfDay(for: plan.estimatedEndTime ?? plan.startTime)
            if (start...end).contains(today) {
                let task = STTask(name: plan.name, date: today, priority: plan.priority ?? .normal, isUrgent: plan.isUrgent, plan: plan)
                context.insert(task)
            }
        }
        
        // Record History
        let history = STHistory(date: today, createdTaskForToday: true)
        context.insert(history)
        
        try? context.save()
    }
    
    private func loadAppSettingToAppState() async {
        let fetch = FetchDescriptor<STAppSetting>()
        if let setting = try? context.fetch(fetch).first {
            appState.setting = setting
        } else {
            let newSetting = STAppSetting()
            context.insert(newSetting)
            try? context.save()
            appState.setting = newSetting
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: STPlan.self,
             STTask.self,
             STHistory.self,
             STAppSetting.self,
        configurations: config
    )

    // Populate sample data
    do {
        let today = Date()
        let plan1 = STPlan(
            name: "Plan Today",
            status: .notStarted,
            startTime: today,
            estimatedEndTime: Calendar.current.date(byAdding: .day, value: 1, to: today)
        )
        let plan2 = STPlan(
            name: "Ongoing Plan",
            status: .inProgress,
            startTime: Calendar.current.date(byAdding: .day, value: -1, to: today)!,
            estimatedEndTime: Calendar.current.date(byAdding: .day, value: 1, to: today)
        )
        let plan3 = STPlan(
            name: "Completed Plan",
            status: .finished,
            isUrgent: true,
            startTime: Calendar.current.date(byAdding: .day, value: -3, to: today)!,
            estimatedEndTime: Calendar.current.date(byAdding: .day, value: -2, to: today)
        )
        container.mainContext.insert(plan1)
        container.mainContext.insert(plan2)
        container.mainContext.insert(plan3)

        let history = STHistory(date: today, createdTaskForToday: true)
        container.mainContext.insert(history)

        let setting = STAppSetting()
        container.mainContext.insert(setting)
    }

    let appState = AppState()
    appState.setting = STAppSetting()

    return HomeView()
        .environmentObject(appState)
        .modelContainer(container)
}
