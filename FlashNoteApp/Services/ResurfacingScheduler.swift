@preconcurrency import UserNotifications
import FlashNoteCore

enum ResurfacingScheduler {
    static let categoryIdentifier = "FLASHNOTE_RESURFACE"

    static func registerCategories() {
        let keepAction = UNNotificationAction(
            identifier: "KEEP",
            title: "Keep",
            options: .foreground
        )
        let archiveAction = UNNotificationAction(
            identifier: "ARCHIVE",
            title: "Archive",
            options: .destructive
        )
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE",
            title: "Snooze (+2 days)",
            options: []
        )

        let category = UNNotificationCategory(
            identifier: categoryIdentifier,
            actions: [keepAction, archiveAction, snoozeAction],
            intentIdentifiers: [],
            hiddenPreviewsBodyPlaceholder: "A thought you saved"
        )

        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    private static let resurfacingService = SpacedResurfacingService()
    private static let schedule = ResurfacingSchedule.default

    static func scheduleResurfacing(for note: Note) {
        guard resurfacingService.shouldResurface(note: note, schedule: schedule) else { return }

        guard var triggerDate = resurfacingService.computeNextResurfaceDate(for: note, schedule: schedule) else {
            return
        }

        // Enforce quiet hours: shift notifications landing in 10pm–8am to 8am
        let quietHoursEnabled = UserDefaults.standard.object(forKey: "quietHoursEnabled") as? Bool ?? true
        if quietHoursEnabled {
            triggerDate = adjustForQuietHours(triggerDate)
        }

        // Enforce daily notification cap
        let maxDaily = UserDefaults.standard.object(forKey: "maxDailyNotifications") as? Int ?? 3
        let adjustedDate = triggerDate
        let noteID = note.id
        let resurfaceCount = note.resurfaceCount
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let calendar = Calendar.current
            let sameDayCount = requests.filter { request in
                guard request.identifier.hasPrefix("resurface-"),
                      let calTrigger = request.trigger as? UNCalendarNotificationTrigger,
                      let fireDate = calTrigger.nextTriggerDate() else { return false }
                return calendar.isDate(fireDate, inSameDayAs: adjustedDate)
            }.count

            guard sameDayCount < maxDaily else {
                FNLog.resurfacing.info("Daily cap (\(maxDaily)) reached for \(adjustedDate); skipping note \(noteID)")
                return
            }

            Self.deliverResurfacing(noteID: noteID, resurfaceCount: resurfaceCount, triggerDate: adjustedDate)
        }
    }

    /// Shift a date out of quiet hours (10pm–8am) to 8am.
    private static func adjustForQuietHours(_ date: Date) -> Date {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        // Quiet hours: 22:00 (10pm) to 07:59 (8am)
        if hour >= 22 {
            // Push to 8am the next day
            let nextDay = calendar.date(byAdding: .day, value: 1, to: date)!
            return calendar.date(bySettingHour: 8, minute: 0, second: 0, of: nextDay)!
        } else if hour < 8 {
            // Push to 8am same day
            return calendar.date(bySettingHour: 8, minute: 0, second: 0, of: date)!
        }
        return date
    }

    private static func deliverResurfacing(noteID: UUID, resurfaceCount: Int, triggerDate: Date) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let interval = schedule.nextInterval(for: resurfaceCount) ?? 86400
        let daysAgo = Int(interval / 86400)

        let content = UNMutableNotificationContent()
        content.title = "A thought from \(daysAgo) day\(daysAgo == 1 ? "" : "s") ago"
        content.body = "You saved a thought — tap to review"
        content.categoryIdentifier = categoryIdentifier
        content.userInfo = ["noteID": noteID.uuidString]
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "resurface-\(noteID.uuidString)-\(resurfaceCount)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                FNLog.resurfacing.error("Failed to schedule: \(error)")
            } else {
                FNLog.resurfacing.info("Scheduled resurface #\(resurfaceCount) for note \(noteID)")
            }
        }
    }

    static func cancelResurfacing(for noteID: UUID) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let ids = requests
                .filter { $0.identifier.hasPrefix("resurface-\(noteID.uuidString)") }
                .map(\.identifier)
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    // MARK: - Daily Reflection (Feature 8)

    private static let dailyReflectionIdentifier = "flashnote-daily-reflection"
    private static let dailyReflectionCategoryIdentifier = "FLASHNOTE_DAILY_REFLECTION"

    static func registerDailyReflectionCategory() {
        let openTriageAction = UNNotificationAction(
            identifier: "OPEN_TRIAGE",
            title: "Review Notes",
            options: .foreground
        )

        let category = UNNotificationCategory(
            identifier: dailyReflectionCategoryIdentifier,
            actions: [openTriageAction],
            intentIdentifiers: [],
            hiddenPreviewsBodyPlaceholder: "Review yesterday's captures"
        )

        let center = UNUserNotificationCenter.current()
        center.getNotificationCategories { existing in
            var categories = existing
            categories.insert(category)
            center.setNotificationCategories(categories)
        }
    }

    static func scheduleDailyReflection() {
        let content = UNMutableNotificationContent()
        content.title = "Yesterday's thoughts"
        content.body = "Tap to review and triage your captures"
        content.categoryIdentifier = dailyReflectionCategoryIdentifier
        content.sound = .default

        // Schedule at 8am daily
        var dateComponents = DateComponents()
        dateComponents.hour = 8
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: dailyReflectionIdentifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                FNLog.resurfacing.error("Failed to schedule daily reflection: \(error)")
            } else {
                FNLog.resurfacing.info("Daily reflection notification scheduled at 8am")
            }
        }
    }

    static func cancelDailyReflection() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [dailyReflectionIdentifier])
    }
}
