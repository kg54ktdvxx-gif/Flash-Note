import Foundation
import Testing
@testable import FlashNote

@Suite("NavigationRouter")
@MainActor
struct NavigationRouterTests {

    // MARK: - Scheme validation

    @Test("ignores non-flashnote scheme")
    func ignoresWrongScheme() {
        let router = NavigationRouter()
        router.handle(url: URL(string: "https://example.com/capture")!)
        #expect(router.selectedTab == .capture) // default, unchanged
        #expect(router.prefillText == nil)
    }

    // MARK: - capture host

    @Test("flashnote://capture selects capture tab")
    func captureHost() {
        let router = NavigationRouter()
        router.selectedTab = .inbox
        router.handle(url: URL(string: "flashnote://capture")!)
        #expect(router.selectedTab == .capture)
    }

    @Test("flashnote://capture?text=hello sets prefillText")
    func captureWithText() {
        let router = NavigationRouter()
        router.handle(url: URL(string: "flashnote://capture?text=hello%20world")!)
        #expect(router.selectedTab == .capture)
        #expect(router.prefillText == "hello world")
    }

    @Test("capture text is truncated to 10,000 characters")
    func captureTextTruncation() {
        let router = NavigationRouter()
        let longText = String(repeating: "a", count: 20_000)
        let encoded = longText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? longText
        router.handle(url: URL(string: "flashnote://capture?text=\(encoded)")!)
        #expect(router.prefillText?.count == 10_000)
    }

    @Test("capture without text does not set prefillText")
    func captureWithoutText() {
        let router = NavigationRouter()
        router.handle(url: URL(string: "flashnote://capture")!)
        #expect(router.prefillText == nil)
    }

    // MARK: - inbox host

    @Test("flashnote://inbox selects inbox tab")
    func inboxHost() {
        let router = NavigationRouter()
        router.handle(url: URL(string: "flashnote://inbox")!)
        #expect(router.selectedTab == .inbox)
    }

    // MARK: - triage host

    @Test("flashnote://triage selects inbox and shows triage")
    func triageHost() {
        let router = NavigationRouter()
        router.handle(url: URL(string: "flashnote://triage")!)
        #expect(router.selectedTab == .inbox)
        #expect(router.showTriage == true)
    }

    // MARK: - note host

    @Test("flashnote://note/{id} sets selectedNoteID")
    func noteHost() {
        let router = NavigationRouter()
        let id = UUID()
        router.handle(url: URL(string: "flashnote://note/\(id.uuidString)")!)
        #expect(router.selectedTab == .inbox)
        #expect(router.selectedNoteID == id)
    }

    @Test("flashnote://note with invalid UUID does not set selectedNoteID")
    func noteHostInvalidUUID() {
        let router = NavigationRouter()
        router.handle(url: URL(string: "flashnote://note/not-a-uuid")!)
        #expect(router.selectedNoteID == nil)
    }

    @Test("flashnote://note without path does not set selectedNoteID")
    func noteHostNoPath() {
        let router = NavigationRouter()
        router.handle(url: URL(string: "flashnote://note")!)
        #expect(router.selectedNoteID == nil)
    }

    // MARK: - Unknown host

    @Test("unknown host does not change state")
    func unknownHost() {
        let router = NavigationRouter()
        let originalTab = router.selectedTab
        router.handle(url: URL(string: "flashnote://unknown")!)
        #expect(router.selectedTab == originalTab)
        #expect(router.selectedNoteID == nil)
        #expect(router.prefillText == nil)
        #expect(router.showTriage == false)
    }
}
