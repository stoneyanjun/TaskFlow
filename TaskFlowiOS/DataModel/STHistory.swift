//
//  STHistory.swift
//  TaskFlowiOS
//
//  Created by stone on 2025/7/22.
//

import SwiftData
import SwiftUI

@Model
class STHistory {
    @Attribute(.unique) var id: UUID = UUID()
    var date: Date
    var createdTaskForToday: Bool

    init(date: Date = .now, createdTaskForToday: Bool) {
        self.date = date
        self.createdTaskForToday = createdTaskForToday
    }
}
