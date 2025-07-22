//
//  NewTaskView.swift
//  TaskFlowiOS
//
//  Created by stone on 2025/7/21.
//

import SwiftUI
import SwiftData

struct NewTaskView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var date: Date = .now
    @State private var note: String = ""
    @State private var review: String = ""
    @State private var priority: PlanPriority = .normal
    @State private var isUrgent: Bool = false
    @State private var notificationTime: Date? = nil
    @State private var selectedPlan: STPlan?
    
    @Query(sort: [SortDescriptor(\STPlan.startTime)]) private var fetchedPlans: [STPlan]
    private var allPlans: [STPlan] {
        fetchedPlans.filter {
            $0.status != .abandoned && $0.status != .finished
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Task Info")) {
                    TextField("Task Name", text: $name)
                    Toggle("High Priority", isOn: Binding(
                        get: { priority == .high },
                        set: { priority = $0 ? .high : .normal }
                    ))
                    Toggle("Urgent", isOn: $isUrgent)
                }
                
                Section(header: Text("Relation")) {
                    Picker("Related STPlan", selection: $selectedPlan) {
                        Text("None").tag(STPlan?.none)
                        ForEach(allPlans) { plan in
                            Text(plan.name).tag(Optional(plan))
                        }
                    }
                }
                
                Section(header: Text("Notes")) {
                    TextField("Note", text: $note)
                    TextField("Review", text: $review)
                }
                
                Section {
                    Button("Save") {
                        let task = STTask(
                            name: name,
                            date: date,
                            note: note.isEmpty ? nil : note,
                            review: review.isEmpty ? nil : review,
                            priority: priority,
                            isUrgent: isUrgent,
                            notificationTime: notificationTime,
                            plan: selectedPlan
                        )
                        context.insert(task)
                        try? context.save()
                        dismiss()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .navigationTitle("New Task")
            .toolbar {
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
    let previewContainer = try! ModelContainer(
        for: STTask.self, STPlan.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    let samplePlan1 = STPlan(
        name: "Marketing STPlan",
        status: .inProgress,  // ✅ included
        priority: .high,
        isUrgent: false,
        startTime: Date()
    )
    
    let samplePlan2 = STPlan(
        name: "Product Launch",
        status: .notStarted,  // ✅ included
        priority: .normal,
        isUrgent: true,
        startTime: Date().addingTimeInterval(86400)
    )
    
    let samplePlan3 = STPlan(
        name: "Abandoned STPlan",
        status: .abandoned,   // ❌ excluded by predicate
        priority: .normal,
        isUrgent: false,
        startTime: Date().addingTimeInterval(-86400)
    )
    
    previewContainer.mainContext.insert(samplePlan1)
    previewContainer.mainContext.insert(samplePlan2)
    previewContainer.mainContext.insert(samplePlan3)

    return NewTaskView()
        .modelContainer(previewContainer)
}
