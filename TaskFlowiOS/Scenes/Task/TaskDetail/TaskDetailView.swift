//
//  TaskDetailView.swift
//  TaskFlowiOS
//
//  Created by stone on 2025/7/21.
//

import SwiftUI
import SwiftData

struct TaskDetailView: View {
    @Bindable var task: STTask
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section(header: Text("Basic Info")) {
                TextField("Name", text: $task.name)

                Toggle("High Priority", isOn: Binding(
                    get: { task.priority == .high },
                    set: { task.priority = $0 ? .high : .normal }
                ))

                Toggle("Urgent", isOn: $task.isUrgent)

                if let plan = task.plan {
                    HStack {
                        Text("Plan: ")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(plan.name)")
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section(header: Text("Addition Info")) {
                TextField("Note", text: Binding($task.note, replacingNilWith: ""))
                TextField("Review", text: Binding($task.review, replacingNilWith: ""))
            }

            Section {
                if task.isFinished {
                    Button("Set to In Progress") {
                        task.isFinished = false
                        task.modifiedDate = .now
                        try? context.save()
                    }
                } else {
                    Button("Finish") {
                        task.isFinished = true
                        task.modifiedDate = .now
                        try? context.save()
                    }
                }
                
                Button("Delete Task", role: .destructive) {
                    context.delete(task)
                    dismiss()
                }
            }
        }
        .navigationTitle("Task Detail")
    }
}

#Preview {
    let previewContainer = try! ModelContainer(
        for: STTask.self, STPlan.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    let samplePlan = STPlan(name: "Preview STPlan", startTime: Date())
    let task = STTask(name: "Sample Task", date: Date(), plan: samplePlan)
    previewContainer.mainContext.insert(task)

    return NavigationStack {
        TaskDetailView(task: task)
    }
    .modelContainer(previewContainer)
}
