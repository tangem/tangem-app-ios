//
//  OSLogFileWriter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import OSLog
import ZIPFoundation
import TangemFoundation

public final class OSLogFileWriter {
    private let loggerSerialQueue = DispatchQueue(label: "com.tangem.OSLogFileWriter.queue")

    private let fileManager: FileManager = .default

    private let logFileURL: URL = FileManager.default
        .urls(for: .cachesDirectory, in: .userDomainMask)[0]
        .appendingPathComponent(OSLogConstants.fileName)

    /// Production redacts persisted logs, non-production keeps the full trace.
    private static let sanitizerPolicy: LogSanitizerPolicy = AppEnvironment.current.isProduction ? .production : .disabled

    /// Cached once per process, matching the pattern used in `DateFormatter+.swift` (BlockchainSdk).
    /// Both formatters are touched only from `loggerSerialQueue`, so they are thread-safe by confinement.
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss:SSS '/' ZZZZ"
        return formatter
    }()

    /// Long-lived write handle. Opened once per process on `loggerSerialQueue` during init
    /// (and re-opened on the first write after `deleteLogFile`), and reused for every
    /// subsequent append.
    /// Access is enforced to `loggerSerialQueue` in DEBUG via the getter/setter below.
    private var _fileHandle: FileHandle?
    private var fileHandle: FileHandle? {
        get {
            assertOnLoggerSerialQueue()
            return _fileHandle
        }
        set {
            assertOnLoggerSerialQueue()
            _fileHandle = newValue
        }
    }

    private init() {
        loggerSerialQueue.async { [weak self] in
            guard let self else { return }
            try? removeLogFileIfNeeded()
            try? createLogFileIfNeeded()
        }
    }

    private func assertOnLoggerSerialQueue() {
        #if DEBUG
        dispatchPrecondition(condition: .onQueue(loggerSerialQueue))
        #endif
    }
}

// MARK: - Public members

public extension OSLogFileWriter {
    static let shared = OSLogFileWriter()

    var logFile: URL { logFileURL }

    func readEntries(completion: @escaping (Result<[OSLogEntry], Error>) -> Void) {
        loggerSerialQueue.async { [weak self] in
            guard let self else { return }
            completion(Result { try self.readEntriesSynchronously() })
        }
    }

    func zipLogFile(infoData: Data? = nil, completion: @escaping (Result<URL, Error>) -> Void) {
        loggerSerialQueue.async { [weak self] in
            guard let self else { return }
            completion(Result { try self.zipLogFileSynchronously(infoData: infoData) })
        }
    }

    func deleteLogFile(completion: @escaping () -> Void) {
        loggerSerialQueue.async { [weak self] in
            guard let self else { return }

            do {
                try deleteLogFileSynchronously()
            } catch {
                OSLog.logger(for: .logFileWriter).fault("\(error.localizedDescription)")
            }

            completion()
        }
    }
}

// MARK: - Internal

extension OSLogFileWriter {
    func write(_ message: String, category: OSLog.Category, level: OSLog.Level, date: Date = .now) {
        loggerSerialQueue.async { [weak self] in
            guard let self else { return }

            do {
                try writeSynchronously(message, category: category, level: level, date: date)
            } catch {
                OSLog.logger(for: .logFileWriter).fault("\(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Private synchronous methods

private extension OSLogFileWriter {
    func writeSynchronously(_ message: String, category: OSLog.Category, level: OSLog.Level, date: Date) throws {
        var message = LogSanitizer.sanitize(message, policy: Self.sanitizerPolicy)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if message.isEmpty {
            // Message can not be empty
            return
        }

        message = message
            // The symbol `,` will be replaced to `¸`
            .replacingOccurrences(of: OSLogConstants.separator, with: OSLogConstants.cedilla)
            // Should checked above but replace it just in case
            .replacingOccurrences(of: "\n", with: OSLogConstants.enter)

        let entry = OSLogEntry(
            date: Self.dateFormatter.string(from: date),
            time: Self.timeFormatter.string(from: date),
            category: category.name,
            level: level.name,
            message: message
        )

        let row = "\n\(entry.encoded(separator: OSLogConstants.separator))"
        try appendRowToLogFile(row)
    }

    func readEntriesSynchronously() throws -> [OSLogEntry] {
        let content = try String(contentsOf: logFileURL)
        let rows: [String] = content.components(separatedBy: "\n")

        return rows
            .dropFirst() // Drop Header
            .compactMap { row in
                let components = row.components(separatedBy: OSLogConstants.separator)
                guard components.count == 5 else {
                    assertionFailure("Wrong OSLogEntry format")
                    return nil
                }

                return OSLogEntry(
                    date: components[0],
                    time: components[1],
                    category: components[2],
                    level: components[3],
                    message: components[4]
                )
            }
    }

    func zipLogFileSynchronously(infoData: Data? = nil) throws -> URL {
        let zipFile = logFileURL
            .deletingLastPathComponent()
            .appendingPathComponent(OSLogConstants.zipFileName)

        if fileManager.fileExists(atPath: zipFile.path) {
            try fileManager.removeItem(at: zipFile)
        }

        guard let infoData else {
            try fileManager.zipItem(at: logFileURL, to: zipFile)
            return zipFile
        }

        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: tempDir) }

        try fileManager.copyItem(at: logFileURL, to: tempDir.appendingPathComponent(logFileURL.lastPathComponent))
        try infoData.write(to: tempDir.appendingPathComponent(OSLogConstants.infoLogs))
        try fileManager.zipItem(at: tempDir, to: zipFile, shouldKeepParent: false)

        return zipFile
    }

    func deleteLogFileSynchronously() throws {
        // Invalidate the long-lived handle before removing the underlying file; the next write
        // will reopen it via `obtainFileHandle()`.
        try? fileHandle?.close()
        fileHandle = nil

        if fileManager.fileExists(atPath: logFileURL.path) {
            try fileManager.removeItem(at: logFileURL)
        }

        let logZipFileURL = logFile
            .deletingLastPathComponent()
            .appendingPathComponent(OSLogConstants.zipFileName)

        if fileManager.fileExists(atPath: logZipFileURL.path) {
            try fileManager.removeItem(at: logZipFileURL)
        }

        try createLogFileIfNeeded()
    }

    func appendRowToLogFile(_ row: String) throws {
        guard let data = row.data(using: .utf8) else {
            throw Errors.wrongRow
        }

        let handle = try obtainFileHandle()
        try handle.write(contentsOf: data)
    }

    /// Returns the long-lived write handle, creating the log file (with header) and opening
    /// the handle on the first call (from `init` or after `deleteLogFile`).
    ///
    /// Must be called on `loggerSerialQueue`.
    func obtainFileHandle() throws -> FileHandle {
        if let fileHandle {
            return fileHandle
        }

        let shouldCreateLogFile = !fileManager.fileExists(atPath: logFileURL.relativePath)
        if shouldCreateLogFile {
            fileManager.createFile(atPath: logFileURL.relativePath, contents: nil)
        }

        let handle = try FileHandle(forWritingTo: logFileURL)
        try handle.seekToEnd()

        if shouldCreateLogFile {
            let header = OSLogEntry.encodedHeader(separator: OSLogConstants.separator)
            if let headerData = header.data(using: .utf8) {
                try handle.write(contentsOf: headerData)
            }
        }

        fileHandle = handle
        return handle
    }

    func createLogFileIfNeeded() throws {
        _ = try obtainFileHandle()
    }

    func removeLogFileIfNeeded() throws {
        let fileAttributes = try fileManager.attributesOfItem(atPath: logFileURL.relativePath)

        guard let creationDate = fileAttributes[.creationDate] as? Date,
              let expirationDate = Calendar.current.date(byAdding: .day, value: OSLogConstants.numberOfDaysUntilExpiration, to: creationDate),
              expirationDate < Date() else {
            return
        }

        try fileManager.removeItem(at: logFileURL)
    }
}

// MARK: - Errors

extension OSLogFileWriter {
    enum Errors: LocalizedError {
        case wrongRow

        var errorDescription: String? {
            switch self {
            case .wrongRow: "Wrong row"
            }
        }
    }
}

private extension OSLogCategory {
    static let logFileWriter = OSLogCategory(name: "LogFileWriter")
}
