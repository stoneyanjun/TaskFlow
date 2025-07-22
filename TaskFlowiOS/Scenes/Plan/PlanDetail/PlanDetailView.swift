//
//  PlanDetailView.swift
//  TaskFlowiOS
//
//  Created by stone on 2025/7/21.
//

import SwiftUI
import SwiftData

struct PlanDetailView: View {
    @Bindable var plan: STPlan
    let allPlans: [STPlan]
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var showAbandonConfirm = false
    @State private var showDeleteConfirm = false

    var isEndStatus: Bool {
        plan.status == .finished || plan.status == .abandoned
    }

    var body: some View {
        Form {
            // Basic Info
            Section(header: Text("Basic Info")) {
                if isEndStatus {
                    Text("Name: \(plan.name)")
                    Text("Status: \(plan.status.displayName)")
                    Text("High Priority: \(plan.priority == .high ? "Yes" : "No")")
                    Text("Urgent: \(plan.isUrgent ? "Yes" : "No")")
                    Text("Start Time: \(format(plan.startTime))")
                    if let estimated = plan.estimatedEndTime {
                        Text("Estimated End: \(format(estimated))")
                    }
                    if let end = plan.endTime {
                        Text("End Time: \(format(end))")
                    }
                } else {
                    TextField("Plan Name", text: $plan.name)
                    HStack {
                        Text("Status:")
                        Spacer()
                        Text(plan.status.displayName)
                    }
                    Toggle("High Priority", isOn: Binding(get: {
                        plan.priority == .high
                    }, set: { plan.priority = $0 ? .high : .normal }))
                    Toggle("Urgent", isOn: $plan.isUrgent)
                    DatePicker("Start Time", selection: $plan.startTime, displayedComponents: .date)
                    DatePicker("Estimated End", selection: Binding($plan.estimatedEndTime, replacingNilWith: Date()), displayedComponents: .date)
                }
            }

            // Notes
            Section(header: Text("Notes")) {
                if isEndStatus {
                    if let note = plan.note {
                        Text("Note: \(note)")
                    }
                } else {
                    TextField("Note", text: Binding($plan.note, replacingNilWith: ""))
                }
                TextField("Review", text: Binding($plan.review, replacingNilWith: ""))
            }

            // Action Buttons
            Section {
                if isEndStatus {
                    Button("Back to In Progress") {
                        plan.setInProgress()
                    }
                } else {
                    Button("Mark Finished") {
                        plan.finished()
                    }

                    Button("Mark Abandoned") {
                        showAbandonConfirm = true
                    }
                    .foregroundColor(.orange)

                    Button("Delete STPlan", role: .destructive) {
                        showDeleteConfirm = true
                    }
                }
            }
        }
        .navigationTitle("Plan Detail")
        .alert("Are you sure?", isPresented: $showAbandonConfirm) {
            Button("Mark Abandoned", role: .destructive) {
                plan.status = .abandoned
                plan.endTime = Date()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will mark the plan as abandoned.")
        }
        .alert("Confirm Deletion", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                context.delete(plan)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete the plan.")
        }
    }

    private func format(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

#Preview {
    var plans: [STPlan] = []
    
    let previewContainer = try! ModelContainer(
        for: STPlan.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    
    let samplePlan = STPlan(
        name: "Sample STPlan",
        status: .inProgress,
        priority: .high,
        isUrgent: true,
        startTime: Date(),
        estimatedEndTime: Date().addingTimeInterval(86400)
    )
    samplePlan.note = "This is a note."
    samplePlan.review = "This is a review."
    
    let samplePlan2 = STPlan(
        name: "So far Parent",
        status: .inProgress,
        priority: .high,
        isUrgent: true,
        startTime: Date(),
        estimatedEndTime: Date().addingTimeInterval(6400)
    )
    samplePlan2.note = "This is a parent note."
    samplePlan2.review = "This is a parent review."
    
    plans.append(samplePlan2)
    
    previewContainer.mainContext.insert(samplePlan)
    
    return NavigationStack {
        PlanDetailView(plan: samplePlan, allPlans: plans)
    }
    .modelContainer(previewContainer)
}
