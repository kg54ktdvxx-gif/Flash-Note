@preconcurrency import UserNotifications
import SwiftData
import FlashNoteCore

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {

    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        super.init()
    }

    // MARK: - Foreground presentation

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    // MARK: - Action handling

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier

        await MainActor.run {
            handleAction(actionIdentifier, userInfo: userInfo)
        }
    }

    // MARK: - Dispatch

    @MainActor
    private func handleAction(_ actionIdentifier: String, userInfo: [AnyHashable: Any]) {
        switch actionIdentifier {
        case "KEEP":
            guard let noteID = noteID(from: userInfo) else { return }
            handleKeep(noteID: noteID)

        case "ARCHIVE":
            guard let noteID = noteID(from: userInfo) else { return }
            handleArchive(noteID: noteID)

        case "SNOOZE":
            guard let noteID = noteID(from: userInfo) else { return }
            handleSnooze(noteID: noteID)

        case "OPEN_TRIAGE":
            DependencyContainer.shared.navigationRouter.selectedTab = .inbox
            DependencyContainer.shared.navigationRouter.showTriage = true

        case UNNotificationDefaultActionIdentifier:
            if let noteID = noteID(from: userInfo) {
                DependencyContainer.shared.navigationRouter.selectedTab = .inbox
                DependencyContainer.shared.navigationRouter.selectedNoteID = noteID
            }

        default:
            break
        }
    }

    // MARK: - Helpers

    private func noteID(from userInfo: [AnyHashable: Any]) -> UUID? {
        guard let idString = userInfo["noteID"] as? String else { return nil }
        return UUID(uuidString: idString)
    }

    @MainActor
    private func handleKeep(noteID: UUID) {
        let context = ModelContext(modelContainer)
        guard let note = fetchNote(id: noteID, context: context) else { return }

        note.resurfaceCount += 1
        note.updatedAt = .now
        do {
            try context.save()
            ResurfacingScheduler.scheduleResurfacing(for: note)
            FNLog.resurfacing.info("Kept note \(noteID), resurface #\(note.resurfaceCount)")
        } catch {
            FNLog.resurfacing.error("Failed to keep note \(noteID): \(error)")
        }
    }

    @MainActor
    private func handleArchive(noteID: UUID) {
        let context = ModelContext(modelContainer)
        guard let note = fetchNote(id: noteID, context: context) else { return }

        note.status = .archived
        note.updatedAt = .now
        ResurfacingScheduler.cancelResurfacing(for: noteID)
        do {
            try context.save()
            FNLog.resurfacing.info("Archived note \(noteID) from notification")
        } catch {
            FNLog.resurfacing.error("Failed to archive note \(noteID): \(error)")
        }
    }

    @MainActor
    private func handleSnooze(noteID: UUID) {
        let context = ModelContext(modelContainer)
        guard let note = fetchNote(id: noteID, context: context) else { return }

        ResurfacingScheduler.cancelResurfacing(for: noteID)

        let snoozeDate = Date.now.addingTimeInterval(2 * 86400)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: snoozeDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let content = UNMutableNotificationContent()
        content.title = "Snoozed thought"
        content.body = "You saved a thought — tap to review"
        content.categoryIdentifier = ResurfacingScheduler.categoryIdentifier
        content.userInfo = ["noteID": noteID.uuidString]
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "resurface-\(noteID.uuidString)-snooze",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                FNLog.resurfacing.error("Failed to snooze note \(noteID): \(error)")
            } else {
                FNLog.resurfacing.info("Snoozed note \(noteID) for 2 days")
            }
        }

        note.updatedAt = .now
        do { try context.save() } catch {
            FNLog.resurfacing.error("Failed to save snoozed note \(noteID): \(error)")
        }
    }

    @MainActor
    private func fetchNote(id: UUID, context: ModelContext) -> Note? {
        let predicate = #Predicate<Note> { $0.id == id }
        let descriptor = FetchDescriptor<Note>(predicate: predicate)
        do {
            return try context.fetch(descriptor).first
        } catch {
            FNLog.resurfacing.error("Failed to fetch note \(id): \(error)")
            return nil
        }
    }
}
