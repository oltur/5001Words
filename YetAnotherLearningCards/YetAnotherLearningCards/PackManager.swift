import Foundation
import Combine

// After uploading .pack files to a GitHub Release, paste the download URLs here.
let packDownloadURLs: [String: String] = [
    "spanish": "https://github.com/oltur/5001Words/releases/download/audio-v1/spanish_audio.pack",
    "dutch":   "https://github.com/oltur/5001Words/releases/download/audio-v1/dutch_audio.pack",
]

class PackManager: NSObject, ObservableObject {

    enum PackState: Equatable {
        case notDownloaded
        case downloading(progress: Double)
        case installed
        case failed(String)

        static func == (lhs: PackState, rhs: PackState) -> Bool {
            switch (lhs, rhs) {
            case (.notDownloaded, .notDownloaded), (.installed, .installed): return true
            case (.downloading(let a), .downloading(let b)): return a == b
            case (.failed(let a), .failed(let b)): return a == b
            default: return false
            }
        }
    }

    static let shared = PackManager()

    @Published var states: [String: PackState] = [:]

    private var deckForTask: [URLSessionTask: Deck] = [:]
    private lazy var session = URLSession(
        configuration: .default, delegate: self, delegateQueue: nil
    )

    var audioRoot: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Audio")
    }

    func audioDirectory(for deck: Deck) -> URL {
        audioRoot.appendingPathComponent(deck.audioFolder)
    }

    override init() {
        super.init()
        refresh()
    }

    func refresh() {
        for deck in availableDecks where !deck.audioFolder.isEmpty {
            if let s = states[deck.id], case .downloading = s { continue }
            states[deck.id] = isInstalled(deck) ? .installed : .notDownloaded
        }
    }

    func isInstalled(_ deck: Deck) -> Bool {
        guard !deck.audioFolder.isEmpty else { return false }
        let files = (try? FileManager.default.contentsOfDirectory(
            atPath: audioDirectory(for: deck).path)) ?? []
        return files.contains { $0.hasSuffix(".mp3") }
    }

    func download(_ deck: Deck) {
        guard let urlString = packDownloadURLs[deck.id],
              let url = URL(string: urlString) else {
            states[deck.id] = .failed("No download URL configured")
            return
        }
        states[deck.id] = .downloading(progress: 0)
        let task = session.downloadTask(with: url)
        deckForTask[task] = deck
        task.resume()
    }

    func cancelDownload(_ deck: Deck) {
        guard let task = deckForTask.first(where: { $0.value.id == deck.id })?.key else { return }
        task.cancel()
        states[deck.id] = .notDownloaded
    }

    func remove(_ deck: Deck) {
        try? FileManager.default.removeItem(at: audioDirectory(for: deck))
        states[deck.id] = .notDownloaded
    }

    // MARK: - Pack extraction

    private enum PackError: LocalizedError {
        case badMagic, truncated
        var errorDescription: String? {
            switch self {
            case .badMagic:   return "Not a valid .pack file"
            case .truncated:  return "Pack file is truncated or corrupt"
            }
        }
    }

    private func unpack(from source: URL, to directory: URL) throws {
        let raw = try Data(contentsOf: source, options: .mappedIfSafe)
        var cursor = raw.startIndex

        func need(_ n: Int) throws {
            guard cursor + n <= raw.endIndex else { throw PackError.truncated }
        }
        func readBytes(_ n: Int) throws -> Data {
            try need(n)
            defer { cursor += n }
            return raw[cursor ..< cursor + n]
        }
        func readU16() throws -> Int {
            let d = try readBytes(2)
            return Int(d[d.startIndex]) << 8 | Int(d[d.startIndex + 1])
        }
        func readU32() throws -> Int {
            let d = try readBytes(4)
            return Int(d[d.startIndex]) << 24 | Int(d[d.startIndex + 1]) << 16
                 | Int(d[d.startIndex + 2]) << 8  | Int(d[d.startIndex + 3])
        }

        guard (try? readBytes(4)) == Data("PACK".utf8) else { throw PackError.badMagic }

        let fileCount = try readU32()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        for _ in 0 ..< fileCount {
            let nameLen = try readU16()
            guard let name = String(data: try readBytes(nameLen), encoding: .utf8) else {
                throw PackError.truncated
            }
            let dataLen = try readU32()
            let fileData = try readBytes(dataLen)
            try fileData.write(to: directory.appendingPathComponent(name))
        }

        // Exclude from iCloud backup
        var dirURL = directory
        var rv = URLResourceValues()
        rv.isExcludedFromBackup = true
        try? dirURL.setResourceValues(rv)
    }
}

// MARK: - URLSessionDownloadDelegate

extension PackManager: URLSessionDownloadDelegate {

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData _: Int64,
        totalBytesWritten written: Int64,
        totalBytesExpectedToWrite expected: Int64
    ) {
        guard let deck = deckForTask[downloadTask] else { return }
        let progress = expected > 0 ? Double(written) / Double(expected) : 0
        DispatchQueue.main.async { self.states[deck.id] = .downloading(progress: progress) }
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        guard let deck = deckForTask.removeValue(forKey: downloadTask) else { return }
        let destDir = audioDirectory(for: deck)
        do {
            try unpack(from: location, to: destDir)
            DispatchQueue.main.async { self.states[deck.id] = .installed }
        } catch {
            DispatchQueue.main.async { self.states[deck.id] = .failed(error.localizedDescription) }
        }
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        guard let error, let deck = deckForTask.removeValue(forKey: task) else { return }
        let nsError = error as NSError
        if nsError.code == NSURLErrorCancelled { return }
        DispatchQueue.main.async { self.states[deck.id] = .failed(error.localizedDescription) }
    }
}
