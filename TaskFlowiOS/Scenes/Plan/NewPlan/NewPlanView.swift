//
//  NewPlanView.swift
//  TaskFlowiOS
//
//  Created by stone on 2025/7/21.
//

import SwiftUI
import SwiftData

struct NewPlanView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var name: String = ""
    @State private var priority: PlanPriority = .normal
    @State private var isUrgent: Bool = false
    @State private var startDate: Date = Date()
    @State private var estimatedEndDate: Date = Date().addingTimeInterval(86400)
    @State private var note: String = ""

    private var todayStart: Date {
        Calendar.current.startOfDay(for: Date())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Basic Info")) {
                    TextField("Plan Name", text: $name)

                    Picker("Priority", selection: $priority) {
                        ForEach(PlanPriority.allCases) { prio in
                            Text(prio.displayName).tag(prio)
                        }
                    }

                    Toggle("Urgent", isOn: $isUrgent)

                    DatePicker("Start Date", selection: $startDate, in: todayStart..., displayedComponents: .date)
                    DatePicker("Estimated End", selection: $estimatedEndDate, in: startDate..., displayedComponents: .date)
                }

                Section(header: Text("Notes")) {
                    TextField("Note", text: $note)
                }
            }
            .navigationTitle("New Plan")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let today = Calendar.current.startOfDay(for: .now)
                        let start = Calendar.current.startOfDay(for: startDate)
                        let end = Calendar.current.startOfDay(for: estimatedEndDate)

                        let status: PlanStatus = start <= today ? .inProgress : .notStarted

                        let newPlan = STPlan(
                            name: name,
                            status: status,
                            priority: priority,
                            isUrgent: isUrgent,
                            startTime: startDate,
                            estimatedEndTime: estimatedEndDate
                        )
                        newPlan.note = note

                        context.insert(newPlan)

                        // Auto-create today's task if date is within plan range
                        if (start...end).contains(today) {
                            let todayTask = STTask(
                                name: name,
                                date: today,
                                priority: priority,
                                isUrgent: isUrgent,
                                plan: newPlan
                            )
                            context.insert(todayTask)
                        }

                        dismiss()
                    }
                    .disabled(
                        name.trimmingCharacters(in: .whitespaces).isEmpty
                        || startDate < todayStart
                        || estimatedEndDate < startDate
                    )
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NewPlanView()
        .modelContainer(for: STPlan.self, inMemory: true)
}
