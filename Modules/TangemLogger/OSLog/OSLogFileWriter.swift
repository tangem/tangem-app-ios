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

    private lazy var fileManager: FileManager = .default

    private lazy var logFileURL: URL = fileManager
        .urls(for: .cachesDirectory, in: .userDomainMask)[0]
        .appendingPathComponent(OSLogConstants.fileName)

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        return formatter
    }()

    private lazy var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss:SSS '/' ZZZZ"
        return formatter
    }()

    private init() {
        try? removeLogFileIfNeeded()
        try? createLogFileIfNeeded()
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

    func zipLogFile(completion: @escaping (Result<URL, Error>) -> Void) {
        loggerSerialQueue.async { [weak self] in
            guard let self else { return }
            completion(Result { try self.zipLogFileSynchronously() })
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
        var message = LogSanitizer.sanitize(message, policy: .production)
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
            date: dateFormatter.string(from: date),
            time: timeFormatter.string(from: date),
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

    func zipLogFileSynchronously() throws -> URL {
        let zipFile = logFileURL
            .deletingLastPathComponent()
            .appendingPathComponent(OSLogConstants.zipFileName)

        if fileManager.fileExists(atPath: zipFile.path) {
            try fileManager.removeItem(at: zipFile)
        }

        try fileManager.zipItem(at: logFileURL, to: zipFile)
        return zipFile
    }

    func deleteLogFileSynchronously() throws {
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
        try createLogFileIfNeeded()

        guard let data = row.data(using: .utf8) else {
            throw Errors.wrongRow
        }

        let handler = try FileHandle(forWritingTo: logFileURL)
        try handler.seekToEnd()
        try handler.write(contentsOf: data)
        try handler.close()
    }

    func createLogFileIfNeeded() throws {
        guard !fileManager.fileExists(atPath: logFileURL.relativePath) else {
            return
        }

        fileManager.createFile(atPath: logFileURL.relativePath, contents: nil)

        // OSLogEntry property names
        let header = OSLogEntry.encodedHeader(separator: OSLogConstants.separator)
        try appendRowToLogFile(header)
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
