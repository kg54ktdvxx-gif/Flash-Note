import Testing
import Foundation
@testable import FlashNoteCore

@Suite("CaptureSource")
struct CaptureSourceTests {
    @Test("raw value round-trip for all cases")
    func rawValueRoundTrip() {
        for source in CaptureSource.allCases {
            let reconstructed = CaptureSource(rawValue: source.rawValue)
            #expect(reconstructed == source)
        }
    }

    @Test("raw values are stable strings")
    func stableRawValues() {
        #expect(CaptureSource.keyboard.rawValue == "keyboard")
        #expect(CaptureSource.voice.rawValue == "voice")
        #expect(CaptureSource.share.rawValue == "share")
        #expect(CaptureSource.siri.rawValue == "siri")
        #expect(CaptureSource.watch.rawValue == "watch")
        #expect(CaptureSource.widget.rawValue == "widget")
    }

    @Test("invalid raw value returns nil")
    func invalidRawValue() {
        #expect(CaptureSource(rawValue: "bogus") == nil)
        #expect(CaptureSource(rawValue: "") == nil)
    }

    @Test("displayName is non-empty for all cases")
    func displayNames() {
        for source in CaptureSource.allCases {
            #expect(!source.displayName.isEmpty)
        }
    }

    @Test("iconName is non-empty for all cases")
    func iconNames() {
        for source in CaptureSource.allCases {
            #expect(!source.iconName.isEmpty)
        }
    }

    @Test("Codable round-trip")
    func codableRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        for source in CaptureSource.allCases {
            let data = try encoder.encode(source)
            let decoded = try decoder.decode(CaptureSource.self, from: data)
            #expect(decoded == source)
        }
    }
}
