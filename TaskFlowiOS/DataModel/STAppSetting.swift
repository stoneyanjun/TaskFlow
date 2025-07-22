//
//  STAppSetting.swift
//  TaskFlowiOS
//
//  Created by stone on 2025/7/21.
//

import Foundation
import SwiftData

@Model
class STAppSetting {
    @Attribute(.unique) var id: UUID = UUID()

    var pomodoroWorkMinutes: Int
    var pomodoroRelaxMinutes: Int
    var enableReviewNotification: Bool
    var reviewNotificationTime: Date

    init(
        pomodoroWorkMinutes: Int = 20,
        pomodoroRelaxMinutes: Int = 3,
        enableReviewNotification: Bool = false,
        reviewNotificationTime: Date = Calendar.current.date(bySettingHour: 18, minute: 15, second: 0, of: Date())!
    ) {
        self.pomodoroWorkMinutes = pomodoroWorkMinutes
        self.pomodoroRelaxMinutes = pomodoroRelaxMinutes
        self.enableReviewNotification = enableReviewNotification
        self.reviewNotificationTime = reviewNotificationTime
    }
}
