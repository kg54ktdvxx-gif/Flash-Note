import SwiftUI
import Observation

enum AppTab: String, Hashable {
    case capture
    case inbox
}

@MainActor @Observable
final class NavigationRouter {
    var selectedTab: AppTab = .capture
    var selectedNoteID: UUID?
    var prefillText: String?
    var showTriage = false

    func handle(url: URL) {
        guard url.scheme == "flashnote" else { return }

        switch url.host {
        case "capture":
            selectedTab = .capture
            if let text = url.queryValue(for: "text") {
                prefillText = String(text.prefix(10_000))
            }
        case "inbox":
            selectedTab = .inbox
        case "triage":
            selectedTab = .inbox
            showTriage = true
        case "note":
            if let idString = url.pathComponents.dropFirst().first,
               let id = UUID(uuidString: idString) {
                selectedTab = .inbox
                selectedNoteID = id
            }
        default:
            break
        }
    }
}

private extension URL {
    func queryValue(for key: String) -> String? {
        URLComponents(url: self, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == key })?
            .value
    }
}
