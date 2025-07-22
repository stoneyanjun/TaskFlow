//
//  STTask.swift
//  TaskFlowiOS
//
//  Created by stone on 2025/7/21.
//

import SwiftUI
import SwiftData

@Model
class STTask: Identifiable {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String
    var date: Date
    var isFinished: Bool = false
    var note: String?
    var review: String?
    var priority = PlanPriority.normal
    var isUrgent: Bool = false
    var notificationTime: Date?
    var createdDate = Date.now
    var modifiedDate = Date.now

    // Relationship
    var plan: STPlan?

    init(name: String,
         date: Date,
         isFinished: Bool = false,
         note: String? = nil,
         review: String? = nil,
         priority: PlanPriority = .normal,
         isUrgent: Bool = false,
         notificationTime: Date? = nil,
         plan: STPlan? = nil) {
        self.name = name
        self.date = date
        self.isFinished = isFinished
        self.note = note
        self.review = review
        self.priority = priority
        self.isUrgent = isUrgent
        self.notificationTime = notificationTime
        self.plan = plan
    }

    func toggleFinished() {
        isFinished.toggle()
        modifiedDate = .now
    }
    
    var color: Color {
        isFinished ? .green : .blue
    }
}
