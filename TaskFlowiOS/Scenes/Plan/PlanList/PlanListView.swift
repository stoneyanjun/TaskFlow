//
//  PlanListView.swift
//  TaskFlowiOS
//
//  Created by stone on 2025/7/21.
//

import SwiftUI
import SwiftData

struct PlanListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\STPlan.startTime)]) private var plans: [STPlan]
    @State private var showNewPlanSheet = false

    var body: some View {
        NavigationStack {
            List {
                // 📌 Active Plans
                Section(header: Text("Plans")) {
                    ForEach(plans.filter { $0.status != .finished && $0.status != .abandoned }) { plan in
                        planRow(for: plan)
                    }
                }

                // 📌 Ended Plans
                Section(header: Text("Ended Plans")) {
                    ForEach(plans.filter { $0.status == .finished || $0.status == .abandoned }) { plan in
                        planRow(for: plan)
                    }
                }
            }
            .navigationTitle("Plans")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showNewPlanSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showNewPlanSheet) {
                NewPlanView()
            }
        }
    }

    @ViewBuilder
    private func planRow(for plan: STPlan) -> some View {
        HStack(spacing: 12) {
            // Tappable leading icon
            if plan.status != .finished && plan.status != .abandoned {
                Button(action: {
                    plan.finished()
                    try? context.save()
                }) {
                    Image(systemName: "arrow.triangle.2.circlepath.circle")
                        .foregroundColor(.blue)
                }
                .buttonStyle(BorderlessButtonStyle())
            } else {
                Image(systemName: "circle")
                    .opacity(0.3)
            }

            NavigationLink(destination: PlanDetailView(plan: plan,
                                                       allPlans: plans.filter { $0.id != plan.id })) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plan.name)
                            .font(.headline)
                            .foregroundColor(plan.status == .finished || plan.status == .abandoned ? .gray : (plan.isUrgent ? .red : .primary))

                        HStack(spacing: 12) {
                            if let formattedDate = formattedDate(plan.startTime) {
                                Text(formattedDate)
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }

                            if plan.status == .finished || plan.status == .abandoned {
                                if let end = plan.endTime,
                                   let formattedEndDate = formattedDate(end) {
                                    Text("→ \(formattedEndDate)")
                                        .font(.footnote)
                                        .foregroundColor(.gray)
                                }
                            } else {
                                if let estimated = plan.estimatedEndTime,
                                   let formattedEstimated = formattedDate(estimated) {
                                    Text("~ \(formattedEstimated)")
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }

                    Spacer()

                    Text(statusIcon(for: plan))
                        .font(.body)
                        .padding(.trailing, 2)
                }
            }
        }
        .padding(.vertical, 6)
    }

    private func statusIcon(for plan: STPlan) -> String {
        switch plan.status {
        case .finished:
            return "✅"
        case .abandoned:
            return "❌"
        default:
            if plan.priority == .high && plan.isUrgent {
                return "🔥"
            } else if plan.priority == .high {
                return "⭐"
            } else if plan.isUrgent {
                return "⏰"
            } else {
                return "🔘"
            }
        }
    }

    private func formattedDate(_ date: Date) -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

#Preview {
    let previewContainer = try! ModelContainer(
        for: STPlan.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    let parentPlan = STPlan(
        name: "Parent STPlan",
        status: .inProgress,
        priority: .high,
        isUrgent: false,
        startTime: Date().addingTimeInterval(-186400),
        estimatedEndTime: Date().addingTimeInterval(113600)
    )

    let childPlan = STPlan(
        name: "Child STPlan",
        status: .notStarted,
        priority: .high,
        isUrgent: true,
        startTime: Date(),
        estimatedEndTime: Date().addingTimeInterval(3600)
    )
    
    let finishedPlan = STPlan(
        name: "Finish STPlan",
        status: .finished,
        priority: .high,
        isUrgent: false,
        startTime: Date().addingTimeInterval(-386400),
        estimatedEndTime: Date().addingTimeInterval(113600)
    )
    finishedPlan.endTime = Date().addingTimeInterval(+3600)

    previewContainer.mainContext.insert(parentPlan)
    previewContainer.mainContext.insert(childPlan)
    previewContainer.mainContext.insert(finishedPlan)

    let abandonedPlan = STPlan(
        name: "Abandoned Plan",
        status: .abandoned,
        priority: .normal,
        isUrgent: false,
        startTime: Date().addingTimeInterval(-7200),
        estimatedEndTime: Date().addingTimeInterval(3600)
    )
    previewContainer.mainContext.insert(abandonedPlan)

    let delayedPlan = STPlan(
        name: "Delayed Plan",
        status: .delayed,
        priority: .high,
        isUrgent: true,
        startTime: Date().addingTimeInterval(-3600),
        estimatedEndTime: Date().addingTimeInterval(7200)
    )
    previewContainer.mainContext.insert(delayedPlan)

    return PlanListView()
        .modelContainer(previewContainer)
}
