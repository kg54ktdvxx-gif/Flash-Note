import Testing
@testable import FlashNoteCore

@Suite("TaskDetectionService")
struct TaskDetectionServiceTests {

    // MARK: - Keyword matching

    @Test("detects 'buy' keyword")
    func detectsBuy() {
        #expect(TaskDetectionService.looksLikeTask("buy milk"))
    }

    @Test("detects 'call' keyword")
    func detectsCall() {
        #expect(TaskDetectionService.looksLikeTask("call the dentist"))
    }

    @Test("detects 'email' keyword")
    func detectsEmail() {
        #expect(TaskDetectionService.looksLikeTask("email Sarah about the meeting"))
    }

    @Test("detects 'schedule' keyword")
    func detectsSchedule() {
        #expect(TaskDetectionService.looksLikeTask("schedule appointment"))
    }

    @Test("detects 'remind' keyword")
    func detectsRemind() {
        #expect(TaskDetectionService.looksLikeTask("remind me to water plants"))
    }

    @Test("detects 'book' keyword")
    func detectsBook() {
        #expect(TaskDetectionService.looksLikeTask("book a flight"))
    }

    @Test("detects 'todo' keyword")
    func detectsTodo() {
        #expect(TaskDetectionService.looksLikeTask("todo: finish report"))
    }

    @Test("detects 'fix' keyword")
    func detectsFix() {
        #expect(TaskDetectionService.looksLikeTask("fix the leaky faucet"))
    }

    @Test("detects 'send' keyword")
    func detectsSend() {
        #expect(TaskDetectionService.looksLikeTask("send the package"))
    }

    @Test("detects 'pick up' multi-word keyword")
    func detectsPickUp() {
        #expect(TaskDetectionService.looksLikeTask("pick up groceries"))
    }

    @Test("detects 'don't forget' multi-word keyword")
    func detectsDontForget() {
        #expect(TaskDetectionService.looksLikeTask("don't forget to lock the door"))
    }

    @Test("detects 'need to' keyword")
    func detectsNeedTo() {
        #expect(TaskDetectionService.looksLikeTask("I need to update my resume"))
    }

    @Test("detects 'have to' keyword")
    func detectsHaveTo() {
        #expect(TaskDetectionService.looksLikeTask("have to finish this by Friday"))
    }

    // MARK: - Case insensitivity

    @Test("case insensitive — uppercase")
    func caseInsensitiveUppercase() {
        #expect(TaskDetectionService.looksLikeTask("BUY milk"))
    }

    @Test("case insensitive — mixed case")
    func caseInsensitiveMixed() {
        #expect(TaskDetectionService.looksLikeTask("Call the dentist"))
    }

    // MARK: - Non-matching text

    @Test("does not match generic text")
    func noMatchGeneric() {
        #expect(!TaskDetectionService.looksLikeTask("thinking about the weather today"))
    }

    @Test("does not match empty string")
    func noMatchEmpty() {
        #expect(!TaskDetectionService.looksLikeTask(""))
    }

    @Test("does not match partial keyword in middle of word")
    func noMatchPartialWord() {
        // "fix" should match at word boundary, but "prefix" should not
        #expect(!TaskDetectionService.looksLikeTask("prefix the filename"))
    }

    @Test("does not match 'buying' (word boundary enforcement)")
    func noMatchBuying() {
        // "buy" should match only at word boundary
        // Note: "buying" starts with "buy" but \b should prevent partial match
        // However, \b matches between "buy" and "ing" since "buy" ends and "i" starts
        // Actually \b(buy)\b requires "buy" to be a complete word. "buying" has "buy" followed by "ing"
        // without a word boundary between them. Let me verify the regex behavior:
        // \bbuy\b would NOT match "buying" because there's no word boundary after 'y' in "buying"
        #expect(!TaskDetectionService.looksLikeTask("I was buying groceries"))
    }

    // MARK: - Keyword in context

    @Test("detects keyword in longer sentence")
    func keywordInContext() {
        #expect(TaskDetectionService.looksLikeTask("After the meeting, I need to prepare the slides"))
    }

    @Test("detects keyword at end of sentence")
    func keywordAtEnd() {
        #expect(TaskDetectionService.looksLikeTask("Someone told me to call"))
    }
}
