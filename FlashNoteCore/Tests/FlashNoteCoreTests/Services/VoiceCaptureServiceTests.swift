import Testing
import Foundation
@testable import FlashNoteCore

@Suite("VoiceCaptureService")
struct VoiceCaptureServiceTests {

    @Test("VoiceCaptureError cases are distinct")
    func errorCasesDistinct() {
        let cases: [VoiceCaptureError] = [
            .alreadyCapturing,
            .notAuthorized,
            .recognizerUnavailable,
        ]
        // All cases should be unique
        for i in 0..<cases.count {
            for j in (i + 1)..<cases.count {
                #expect(String(describing: cases[i]) != String(describing: cases[j]))
            }
        }
    }

    @Test("VoiceCaptureError conforms to Error and Sendable")
    func errorConformance() {
        let error: any Error & Sendable = VoiceCaptureError.notAuthorized
        #expect(error is VoiceCaptureError)
    }

    @Test("VoiceCaptureError has three cases")
    func errorCaseCount() {
        let cases: [VoiceCaptureError] = [
            .alreadyCapturing,
            .notAuthorized,
            .recognizerUnavailable,
        ]
        #expect(cases.count == 3)
    }

    #if os(iOS)
    @Test("OnDeviceVoiceCaptureService can be initialized")
    func serviceInit() {
        let service = OnDeviceVoiceCaptureService()
        #expect(service is VoiceCaptureService)
    }
    #endif
}
