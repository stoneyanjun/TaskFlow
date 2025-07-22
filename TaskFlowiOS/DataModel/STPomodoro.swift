//
//  STPomodoro.swift
//  TaskFlowiOS
//
//  Created by stone on 2025/7/22.
//

import SwiftData
import SwiftUI

@Model
class STPomodoro {
    @Attribute(.unique) var id: UUID = UUID()
    var task: STTask?
    var startDate: Date
    var endDate: Date?
    var status = PomodoroStatus.finished
    var estimatedMinutes: Int
    var finishedMinutes: Int?

    init(task: STTask?, startDate: Date = Date(), estimatedMinutes: Int = 25) {
        self.task = task
        self.startDate = startDate
        self.estimatedMinutes = estimatedMinutes
    }
}

enum PomodoroStatus: String, Codable, CaseIterable {
    case finished
    case abandoned

    var displayName: String {
        switch self {
        case .finished:
            return "Finished"
        case .abandoned:
            return "Abandoned"
        }
    }
    
    var color: Color {
        switch self {
        case .finished: return .green
        case .abandoned: return .red
        }
    }
}
