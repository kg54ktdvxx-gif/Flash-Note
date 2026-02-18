import UserNotifications
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

        guard let triggerDate = resurfacingService.computeNextResurfaceDate(for: note, schedule: schedule) else {
            return
        }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let interval = schedule.nextInterval(for: note.resurfaceCount) ?? 86400
        let daysAgo = Int(interval / 86400)

        let content = UNMutableNotificationContent()
        content.title = "A thought from \(daysAgo) day\(daysAgo == 1 ? "" : "s") ago"
        content.body = "You saved a thought — tap to review"
        content.categoryIdentifier = categoryIdentifier
        content.userInfo = ["noteID": note.id.uuidString]
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "resurface-\(note.id.uuidString)-\(note.resurfaceCount)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                FNLog.resurfacing.error("Failed to schedule: \(error)")
            } else {
                FNLog.resurfacing.info("Scheduled resurface #\(note.resurfaceCount) for note \(note.id)")
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
