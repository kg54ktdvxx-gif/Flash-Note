import SwiftUI
import SwiftData
import UserNotifications
import FlashNoteCore

@MainActor
final class DependencyContainer: Sendable {
    static let shared = DependencyContainer()

    let modelContainer: ModelContainer
    let navigationRouter: NavigationRouter
    let hapticService: HapticService
    private let notificationDelegate: NotificationDelegate

    private init() {
        do {
            let schema = Schema([Note.self])
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none
            )
            modelContainer = try ModelContainer(
                for: schema,
                migrationPlan: NoteMigrationPlan.self,
                configurations: [config]
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        navigationRouter = NavigationRouter()
        hapticService = HapticService()
        notificationDelegate = NotificationDelegate(modelContainer: modelContainer)
    }

    func setupWatchConnectivity() {
        WatchConnectivityManager.shared.activate()
    }

    func setupNotifications() {
        let center = UNUserNotificationCenter.current()
        center.delegate = notificationDelegate
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error {
                FNLog.resurfacing.error("Notification authorization failed: \(error)")
                return
            }
            guard granted else {
                FNLog.resurfacing.info("Notification authorization denied by user")
                return
            }
            FNLog.resurfacing.info("Notification authorization granted")
        }

        ResurfacingScheduler.registerCategories()
        ResurfacingScheduler.registerDailyReflectionCategory()

        if UserDefaults.standard.object(forKey: "dailyReflectionEnabled") as? Bool ?? false {
            ResurfacingScheduler.scheduleDailyReflection()
        }
    }
}
