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

    static func scheduleResurfacing(for note: Note) {
        let intervals: [TimeInterval] = [
            1 * 86400,   // 1 day
            3 * 86400,   // 3 days
            7 * 86400,   // 7 days
            14 * 86400,  // 14 days
            30 * 86400   // 30 days
        ]

        guard note.resurfaceCount < intervals.count else { return }

        let interval = intervals[note.resurfaceCount]
        let triggerDate = note.createdAt.addingTimeInterval(interval)

        // Enforce quiet hours: 10pm-8am
        var calendar = Calendar.current
        calendar.timeZone = .current
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        if let hour = components.hour, hour >= 22 || hour < 8 {
            components.hour = 8
            components.minute = 0
            if hour >= 22 {
                // Late evening → push to 8am next day
                if let day = components.day { components.day = day + 1 }
            }
            // Early morning (0-7) → push to 8am same day
        }

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let daysAgo = Int(interval / 86400)

        let content = UNMutableNotificationContent()
        content.title = "A thought from \(daysAgo) day\(daysAgo == 1 ? "" : "s") ago"
        content.body = String(note.text.prefix(100))
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
}
