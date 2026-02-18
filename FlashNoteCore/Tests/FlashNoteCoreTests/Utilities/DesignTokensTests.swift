import Testing
@testable import FlashNoteCore

@Suite("DesignTokens")
struct DesignTokensTests {

    @Test("accent light values are vermillion")
    func accentLight() {
        let a = DesignTokens.accent
        #expect(a.lightR > 0.8 && a.lightR < 0.85)  // ~0.83
        #expect(a.lightG > 0.2 && a.lightG < 0.25)   // ~0.22
        #expect(a.lightB > 0.15 && a.lightB < 0.2)    // ~0.17
    }

    @Test("accent dark values are brighter vermillion")
    func accentDark() {
        let a = DesignTokens.accent
        #expect(a.darkR > a.lightR) // dark is brighter
    }

    @Test("background light values are warm paper")
    func backgroundLight() {
        let b = DesignTokens.background
        #expect(b.lightR > 0.97)  // near-white
        #expect(b.lightG > 0.97)
        #expect(b.lightB > 0.96)
    }

    @Test("background dark values are near-black")
    func backgroundDark() {
        let b = DesignTokens.background
        #expect(b.darkR < 0.05)   // near-black
        #expect(b.darkG < 0.05)
        #expect(b.darkB < 0.05)
    }
}
