import SwiftUI
import SwiftData
import FlashNoteCore

@MainActor
final class DependencyContainer: Sendable {
    static let shared = DependencyContainer()

    let modelContainer: ModelContainer
    let navigationRouter: NavigationRouter
    let hapticService: HapticService

    private init() {
        do {
            let schema = Schema([Note.self])
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none
            )
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        navigationRouter = NavigationRouter()
        hapticService = HapticService()
    }

    func setupNotifications() {
        ResurfacingScheduler.registerCategories()
    }
}
