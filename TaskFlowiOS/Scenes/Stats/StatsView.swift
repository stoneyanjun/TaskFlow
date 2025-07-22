//
//  StatsView.swift
//  TaskFlowiOS
//
//  Created by stone on 2025/7/21.
//

import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    enum TimeRange: String, CaseIterable, Identifiable {
        case today, week, month, total
        var id: String { rawValue }

        var title: String {
            switch self {
            case .today: return "Today"
            case .week: return "This Week"
            case .month: return "This Month"
            case .total: return "Total"
            }
        }
    }

    enum DataType: String, CaseIterable, Identifiable {
        case pomodoro, task, plan
        var id: String { rawValue }

        var title: String {
            switch self {
            case .pomodoro: return "Pomodoro"
            case .task: return "Task"
            case .plan: return "Plan"
            }
        }
    }

    struct ChartItem: Identifiable {
        let id = UUID()
        let label: String
        let count: Int
        let color: Color
    }

    @State private var selectedType: DataType = .pomodoro
    @State private var selectedRange: TimeRange = .today

    @Query private var allPomodoros: [STPomodoro]
    @Query private var allTasks: [STTask]
    @Query private var allPlans: [STPlan]

    private var dateRange: (start: Date, end: Date)? {
        let now = Date()
        let calendar = Calendar.current

        switch selectedRange {
        case .today:
            let start = calendar.startOfDay(for: now)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            return (start, end)
        case .week:
            let start = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            let end = calendar.date(byAdding: .day, value: 7, to: start)!
            return (start, end)
        case .month:
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let end = calendar.date(byAdding: .month, value: 1, to: start)!
            return (start, end)
        case .total:
            return nil
        }
    }

    private var chartData: [ChartItem] {
        switch selectedType {
        case .pomodoro:
            let filtered = dateFiltered(allPomodoros, by: \STPomodoro.startDate)
            let grouped = Dictionary(grouping: filtered, by: { $0.status })
            return PomodoroStatus.allCases.compactMap { status in
                let count = grouped[status]?.count ?? 0
                return count > 0 ? ChartItem(label: status.displayName, count: count, color: status.color) : nil
            }

        case .task:
            let filtered = dateFiltered(allTasks, by: \STTask.date)
            let finished = filtered.filter { $0.isFinished }
            let unfinished = filtered.filter { !$0.isFinished }
            return [
                ChartItem(label: "Finished", count: finished.count, color: .green),
                ChartItem(label: "Unfinished", count: unfinished.count, color: .blue)
            ].filter { $0.count > 0 }

        case .plan:
            let filtered = dateFiltered(allPlans, by: \STPlan.startTime)
            let grouped = Dictionary(grouping: filtered, by: { $0.status })
            return PlanStatus.allCases.compactMap { status in
                let count = grouped[status]?.count ?? 0
                return count > 0 ? ChartItem(label: status.displayName, count: count, color: status.color) : nil
            }
        }
    }

    private func dateFiltered<T>(_ items: [T], by keyPath: KeyPath<T, Date>) -> [T] {
        guard let range = dateRange else { return items }
        return items.filter {
            let date = $0[keyPath: keyPath]
            return date >= range.start && date < range.end
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            Picker("Data Type", selection: $selectedType) {
                ForEach(DataType.allCases) { type in
                    Text(type.title).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            Picker("Time Range", selection: $selectedRange) {
                ForEach(TimeRange.allCases) { range in
                    Text(range.title).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            Spacer()

            if chartData.isEmpty {
                Text("No data available")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                Chart(chartData) { item in
                    SectorMark(
                        angle: .value("Count", item.count),
                        innerRadius: .ratio(0.5),
                        angularInset: 2.5
                    )
                    .foregroundStyle(item.color)
                    .annotation(position: .overlay) {
                        Text("\(item.count)")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                }
                .frame(height: 300)
                .padding()

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(chartData) { item in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(item.color)
                                .frame(width: 12, height: 12)
                            Text(item.label)
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding(.top, 4)
            }

            Spacer()
        }
        .navigationTitle("Stats")
    }
}


#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: STPomodoro.self, STTask.self, STPlan.self, configurations: config)

    let today = Calendar.current.startOfDay(for: .now)

    // MARK: - Sample Pomodoros (all statuses)
    let pFinished = STPomodoro(task: nil, startDate: today, estimatedMinutes: 25)
    pFinished.status = .finished

    let pAbandoned = STPomodoro(task: nil, startDate: today, estimatedMinutes: 25)
    pAbandoned.status = .abandoned

    container.mainContext.insert(pFinished)
    container.mainContext.insert(pAbandoned)

    // MARK: - Sample Tasks (finished + unfinished)
    let tFinished = STTask(name: "Finished Task", date: today)
    tFinished.isFinished = true

    let tUnfinished = STTask(name: "Unfinished Task", date: today)

    container.mainContext.insert(tFinished)
    container.mainContext.insert(tUnfinished)

    // MARK: - Sample Plans (all statuses)
    let planNotStarted = STPlan(name: "Plan Not Started", status: .notStarted, startTime: today)
    let planInProgress = STPlan(name: "Plan In Progress", status: .inProgress, startTime: today)
    let planFinished = STPlan(name: "Plan Finished", status: .finished, startTime: today)
    let planAbandoned = STPlan(name: "Plan Abandoned", status: .abandoned, startTime: today)
    let planDelayed = STPlan(name: "Plan Delayed", status: .delayed, startTime: today)

    container.mainContext.insert(planNotStarted)
    container.mainContext.insert(planInProgress)
    container.mainContext.insert(planFinished)
    container.mainContext.insert(planAbandoned)
    container.mainContext.insert(planDelayed)

    return NavigationStack {
        StatsView()
    }
    .modelContainer(container)
}
