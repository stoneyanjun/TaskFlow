//
//  TaskListView.swift
//  TaskFlowiOS
//
//  Created by stone on 2025/7/21.
//

import SwiftUI
import SwiftData

struct TaskListView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var appState: AppState

    @Query(sort: [SortDescriptor(\STTask.date)])
    private var allTasks: [STTask]

    private var todayTasks: [STTask] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        return allTasks.filter { $0.date >= today && $0.date < tomorrow }
    }

    private var unfinishedTasks: [STTask] {
        todayTasks.filter { !$0.isFinished }
    }

    private var finishedTasks: [STTask] {
        todayTasks.filter { $0.isFinished }
    }

    @State private var showNewTaskSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    taskSection(title: "High Priority & Urgent", tasks: unfinishedTasks.filter { $0.priority == .high && $0.isUrgent })
                    taskSection(title: "High Priority", tasks: unfinishedTasks.filter { $0.priority == .high && !$0.isUrgent })
                    taskSection(title: "Urgent", tasks: unfinishedTasks.filter { $0.priority != .high && $0.isUrgent })
                    taskSection(title: "Others", tasks: unfinishedTasks.filter { $0.priority != .high && !$0.isUrgent })
                    taskSection(title: "Finished Tasks", tasks: finishedTasks)
                }
                .padding()
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showNewTaskSheet = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showNewTaskSheet) {
                NewTaskView()
            }
        }
    }

    @ViewBuilder
    private func taskSection(title: String, tasks: [STTask]) -> some View {
        if !tasks.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)

                ForEach(tasks) { task in
                    NavigationLink(destination: TaskDetailView(task: task)) {
                        HStack(spacing: 12) {
                            // Toggle finished
                            Button {
                                task.toggleFinished()
                                try? context.save()
                            } label: {
                                Image(systemName: leadingIcon(for: task))
                                    .foregroundColor(task.isFinished ? .gray : .blue)
                            }
                            .buttonStyle(.borderless)

                            // Task info
                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.name)
                                    .font(.body)
                                    .foregroundColor(task.isFinished ? .gray : (task.isUrgent ? .red : .primary))
                                if let planName = task.plan?.name {
                                    Text(planName)
                                        .font(.footnote)
                                        .foregroundColor(.gray)
                                }
                            }

                            Spacer()

                            // Play Pomodoro
                            let isDisabled = task.isFinished || task.plan?.status == .abandoned
                            Button {
                                let pom = STPomodoro(
                                    task: nil,
                                    startDate: Date(),
                                    estimatedMinutes: appState.setting?.pomodoroWorkMinutes ?? 25,
                                )
                                print(pom.estimatedMinutes)
                                context.insert(pom)
                                pom.task = task
                                try? context.save()

                                appState.startingPomodoro = pom
                                appState.selectedTab = .pomodoro
                            } label: {
                                Image(systemName: "play.circle")
                                    .foregroundColor(isDisabled ? .gray : .green)
                                    .font(.title2)
                            }
                            .disabled(isDisabled)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private func leadingIcon(for task: STTask) -> String {
        if task.isFinished { return "checkmark.circle" }
        if task.priority == .high && task.isUrgent { return "flame" }
        if task.priority == .high { return "star" }
        if task.isUrgent { return "alarm" }
        return "circle"
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: STTask.self, STPlan.self, STPomodoro.self, configurations: config)

    let today = Calendar.current.startOfDay(for: .now)

    // Sample Plan
    let plan = STPlan(name: "Sample Plan", status: .inProgress, startTime: today)
    container.mainContext.insert(plan)

    // Sample Tasks
    let task1 = STTask(name: "Urgent & High", date: today, priority: .high, isUrgent: true, plan: plan)
    task1.isFinished = true
    let task2 = STTask(name: "High Only", date: today, priority: .high, isUrgent: false, plan: plan)
    let task3 = STTask(name: "Urgent Only", date: today, priority: .normal, isUrgent: true, plan: plan)
    let task4 = STTask(name: "Other", date: today, priority: .normal, isUrgent: false, plan: plan)
    task4.isFinished = false
    let task5 = STTask(name: "Finished", date: today, priority: .normal, isUrgent: false, plan: plan)
    task5.isFinished = true

    [task1, task2, task3, task4, task5].forEach { container.mainContext.insert($0) }

    return TaskListView()
        .environmentObject(AppState()) // required if your view uses @EnvironmentObject
        .modelContainer(container)
}
