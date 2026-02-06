import Foundation

public protocol HotCaptureBufferService: Sendable {
    func append(_ entry: BufferEntry) throws
    func readAll() throws -> [BufferEntry]
    func clear() throws
}

public final class FileBasedHotCaptureBuffer: HotCaptureBufferService, @unchecked Sendable {
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let lock = NSLock()

    public init(fileURL: URL = AppGroupContainer.hotBufferFileURL) {
        self.fileURL = fileURL
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }

    public func append(_ entry: BufferEntry) throws {
        let data = try encoder.encode(entry)
        guard var line = String(data: data, encoding: .utf8) else {
            throw BufferError.encodingFailed
        }
        line.append("\n")

        guard let lineData = line.data(using: .utf8) else {
            throw BufferError.encodingFailed
        }

        try lock.withLock {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                let handle = try FileHandle(forWritingTo: fileURL)
                defer { try? handle.close() }
                handle.seekToEndOfFile()
                handle.write(lineData)
            } else {
                try lineData.write(to: fileURL, options: .atomic)
            }
        }

        FNLog.buffer.debug("Appended entry \(entry.id) to buffer")
    }

    public func readAll() throws -> [BufferEntry] {
        try lock.withLock {
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                return []
            }

            let content = try String(contentsOf: fileURL, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }

            return lines.compactMap { line in
                guard let data = line.data(using: .utf8) else { return nil }
                let entry = try? decoder.decode(BufferEntry.self, from: data)
                if entry == nil {
                    FNLog.buffer.warning("Skipped corrupt buffer entry")
                }
                return entry
            }
        }
    }

    public func clear() throws {
        try lock.withLock {
            guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
            try FileManager.default.removeItem(at: fileURL)
            FNLog.buffer.debug("Buffer cleared")
        }
    }
}

public enum BufferError: Error {
    case encodingFailed
}
