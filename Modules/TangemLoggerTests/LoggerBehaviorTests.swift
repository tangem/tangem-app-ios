//
//  LoggerBehaviorTests.swift
//  TangemModules
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//
//  Characterization tests for `Logger`, `OSLog.logger(for:)`, and `OSLogFileWriter`.
//  The suite is serialized because it mutates `Logger.configuration` and shares
//  the single `OSLogFileWriter.shared` instance (which writes to a process-wide
//  caches-directory file).
//

import Foundation
import struct os.OSAllocatedUnfairLock
import Testing
@testable import TangemLogger

@Suite(.serialized)
final class LoggerBehaviorTests {
    private let anyCategory = OSLogCategory(name: "behavior-test", prefix: .none)

    init() async {
        Logger.configuration = Logger.DefaultConfiguration()
        await Self.resetLogFile()
    }

    deinit {
        Logger.configuration = Logger.DefaultConfiguration()
    }

    // MARK: - Autoclosure gating in Logger.log

    @Test
    func autoclosureIsNotEvaluated_whenBothGatesAreOff() async {
        Logger.configuration = FixedConfiguration(loggable: false, writable: false)
        let counter = OSAllocatedUnfairLock(initialState: 0)
        let logger = Logger(category: OSLogCategory(name: "gate-off"))

        logger.debug(counter.withLock { $0 += 1; return "counter-message" })

        await Self.flushLogWriter()

        #expect(counter.withLock { $0 } == 0)
    }

    @Test
    func autoclosureIsEvaluated_whenWritableGateIsOn() async {
        Logger.configuration = FixedConfiguration(loggable: false, writable: true)
        let counter = OSAllocatedUnfairLock(initialState: 0)
        let logger = Logger(category: OSLogCategory(name: "gate-writable"))

        logger.debug(counter.withLock { $0 += 1; return "counter-message" })

        await Self.flushLogWriter()

        #expect(counter.withLock { $0 } == 1)
    }

    @Test
    func autoclosureIsEvaluated_whenLoggableGateIsOn() async {
        Logger.configuration = FixedConfiguration(loggable: true, writable: false)
        let counter = OSAllocatedUnfairLock(initialState: 0)
        let logger = Logger(category: OSLogCategory(name: "gate-loggable"))

        logger.debug(counter.withLock { $0 += 1; return "counter-message" })

        await Self.flushLogWriter()

        #expect(counter.withLock { $0 } == 1)
    }

    // MARK: - File-writer side effect of Logger.log

    @Test
    func loggerDebug_writesToFile_whenWritableIsOn() async throws {
        Logger.configuration = FixedConfiguration(loggable: false, writable: true)
        let logger = Logger(category: OSLogCategory(name: "landing", prefix: .none))

        logger.debug("payload-landed")

        let entries = try await Self.readEntries()
        let matching = entries.filter { $0.message == "payload-landed" }
        #expect(matching.count == 1)
        #expect(matching.first?.category == "landing")
        #expect(matching.first?.level == OSLogLevel.debug.name)
    }

    @Test
    func loggerDebug_doesNotWriteToFile_whenWritableIsOff() async throws {
        Logger.configuration = FixedConfiguration(loggable: true, writable: false)
        let logger = Logger(category: OSLogCategory(name: "suppressed", prefix: .none))

        logger.debug("payload-suppressed")

        await Self.flushLogWriter()

        let entries = try await Self.readEntries()
        #expect(entries.allSatisfy { $0.message != "payload-suppressed" })
    }

    @Test
    func tag_isAppendedToCategoryName_inWrittenEntry() async throws {
        Logger.configuration = FixedConfiguration(loggable: false, writable: true)
        let logger = Logger(category: OSLogCategory(name: "base", prefix: .none)).tag("sub")

        logger.debug("tagged-payload")

        let entries = try await Self.readEntries()
        let matching = entries.filter { $0.message == "tagged-payload" }
        #expect(matching.first?.category == "base [sub]")
    }

    // MARK: - OSLogFileWriter: round trip

    @Test
    func fileWriter_writeThenRead_returnsTheEntry() async throws {
        OSLogFileWriter.shared.write("hello-world", category: anyCategory, level: .info)

        let entries = try await Self.readEntries()

        #expect(entries.count == 1)
        #expect(entries.first?.message == "hello-world")
        #expect(entries.first?.category == "behavior-test")
        #expect(entries.first?.level == OSLogLevel.info.name)
    }

    @Test
    func fileWriter_writeMultipleEntries_preservesFIFOOrder() async throws {
        for index in 0 ..< 10 {
            OSLogFileWriter.shared.write("msg-\(index)", category: anyCategory, level: .debug)
        }

        let entries = try await Self.readEntries()
        let messages = entries.map(\.message)

        #expect(messages == (0 ..< 10).map { "msg-\($0)" })
    }

    @Test
    func fileWriter_preservesChronologicalOrder_forExplicitDates() async throws {
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        let inputDates = (0 ..< 15).map { base.addingTimeInterval(TimeInterval($0 * 3_600)) }

        for (index, date) in inputDates.enumerated() {
            OSLogFileWriter.shared.write("ordered-\(index)", category: anyCategory, level: .info, date: date)
        }

        let entries = try await Self.readEntries()

        // 1. Write order is preserved in the file.
        #expect(entries.map(\.message) == (0 ..< 15).map { "ordered-\($0)" })

        // 2. Parsed date + time columns round-trip into `Date` values that are
        //    monotonically non-decreasing — i.e., chronological order matches write order.
        let parser = DateFormatter()
        parser.dateFormat = "dd-MM-yyyy HH:mm:ss:SSS '/' ZZZZ"
        let parsed = entries.compactMap { parser.date(from: "\($0.date) \($0.time)") }
        #expect(parsed.count == entries.count)
        for index in 1 ..< parsed.count {
            #expect(parsed[index - 1] <= parsed[index])
        }
    }

    // MARK: - OSLogFileWriter: delete

    @Test
    func fileWriter_delete_clearsAllEntries() async throws {
        OSLogFileWriter.shared.write("a", category: anyCategory, level: .info)
        OSLogFileWriter.shared.write("b", category: anyCategory, level: .info)

        await Self.resetLogFile()

        let entries = try await Self.readEntries()
        #expect(entries.isEmpty)
    }

    @Test
    func fileWriter_deleteFollowedByWrite_storesNewEntry() async throws {
        OSLogFileWriter.shared.write("before-delete", category: anyCategory, level: .info)
        await Self.resetLogFile()

        OSLogFileWriter.shared.write("after-delete", category: anyCategory, level: .info)

        let entries = try await Self.readEntries()
        #expect(entries.count == 1)
        #expect(entries.first?.message == "after-delete")
    }

    // MARK: - OSLogFileWriter: zip

    @Test
    func fileWriter_zip_producesFileAtExpectedPath() async throws {
        OSLogFileWriter.shared.write("to-be-zipped", category: anyCategory, level: .info)

        let zipURL = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
            OSLogFileWriter.shared.zipLogFile { continuation.resume(with: $0) }
        }

        #expect(FileManager.default.fileExists(atPath: zipURL.path))
    }

    // MARK: - OSLogFileWriter: concurrency

    @Test
    func fileWriter_concurrentWrites_allLandInFile() async throws {
        let totalWrites = 200

        await withTaskGroup(of: Void.self) { group in
            for index in 0 ..< totalWrites {
                let category = anyCategory
                group.addTask {
                    OSLogFileWriter.shared.write("c-\(index)", category: category, level: .info)
                }
            }
        }

        let entries = try await Self.readEntries()
        let concurrentEntries = entries.filter { $0.message.hasPrefix("c-") }
        #expect(concurrentEntries.count == totalWrites)
    }

    @Test
    func fileWriter_concurrentWrites_doNotCorruptEntries() async throws {
        let totalWrites = 200

        await withTaskGroup(of: Void.self) { group in
            for index in 0 ..< totalWrites {
                let category = anyCategory
                group.addTask {
                    OSLogFileWriter.shared.write("payload-\(index)", category: category, level: .info)
                }
            }
        }

        let entries = try await Self.readEntries()
        let payloadEntries = entries.filter { $0.message.hasPrefix("payload-") }

        #expect(payloadEntries.count == totalWrites)

        for entry in payloadEntries {
            #expect(!entry.date.isEmpty)
            #expect(!entry.time.isEmpty)
            #expect(entry.category == "behavior-test")
            #expect(entry.level == OSLogLevel.info.name)
            #expect(entry.message.hasPrefix("payload-"))
        }
    }

    // MARK: - OSLogFileWriter: CSV encoding

    @Test
    func fileWriter_messageWithComma_isEscapedToCedillaOnRead() async throws {
        OSLogFileWriter.shared.write("one, two, three", category: anyCategory, level: .info)

        let entries = try await Self.readEntries()
        #expect(entries.count == 1)
        #expect(entries.first?.message.contains(",") == false)
        #expect(entries.first?.message.contains("¸") == true)
    }

    @Test
    func fileWriter_messageWithNewline_isEscapedOnRead() async throws {
        OSLogFileWriter.shared.write("line1\nline2", category: anyCategory, level: .info)

        let entries = try await Self.readEntries()
        #expect(entries.count == 1)
        #expect(entries.first?.message.contains("\n") == false)
    }

    // MARK: - OSLog.logger(for:) thread safety

    @Test
    func osLogLoggerForCategory_isSafeUnderContention() async {
        // This test ensures the logger lookup does not crash or deadlock when
        // many threads hit it simultaneously. It exists to guard the invariant
        // during the refactor that moves the cache into `OSLogCategory`.
        let iterations = 500

        await withTaskGroup(of: Void.self) { group in
            for index in 0 ..< iterations {
                group.addTask {
                    let category = OSLogCategory(name: "stress-\(index % 16)")
                    let logger = OSLog.logger(for: category)
                    logger.log(level: .info, message: "stress")
                }
            }
        }

        // Reaching this point without a crash is the assertion.
        #expect(Bool(true))
    }

    // MARK: - Helpers

    private static func resetLogFile() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            OSLogFileWriter.shared.deleteLogFile {
                continuation.resume()
            }
        }
    }

    /// Drains any pending writes by issuing a read through the same serial queue.
    private static func flushLogWriter() async {
        _ = try? await readEntries()
    }

    private static func readEntries() async throws -> [OSLogEntry] {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[OSLogEntry], Error>) in
            OSLogFileWriter.shared.readEntries { continuation.resume(with: $0) }
        }
    }
}

// MARK: - Test doubles

private struct FixedConfiguration: Logger.Configuration {
    let loggable: Bool
    let writable: Bool

    func shouldLogMessage(with logLevel: Logger.Level) -> Bool { loggable }
    func shouldWriteMessage(with logLevel: Logger.Level) -> Bool { writable }
}
