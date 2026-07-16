//
//  CachesDirectoryStorage.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

/// Safe to share: immutable value type; encoder/decoder are only used for encode/decode.
public struct CachesDirectoryStorage: @unchecked Sendable {
    private let file: File
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    // Internal

    private let queue: DispatchQueue
    private var fileManager: FileManager { .default }
    private var fileURL: URL {
        fileManager
            .urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(file.name)
            .appendingPathExtension("json")
    }

    public init(file: File, encoder: JSONEncoder = .init(), decoder: JSONDecoder = .init()) {
        self.file = file
        self.encoder = encoder
        self.decoder = decoder
        queue = Self.queue(for: file)
    }
}

// MARK: - Shared per-file queue

private extension CachesDirectoryStorage {
    /// Distinct `CachesDirectoryStorage` instances constructed for the same `file` back the same on-disk JSON,
    /// so their read-modify-write sequences (e.g. in callers that read the current value, mutate it, and store it
    /// back) must share one serial-for-writes queue — otherwise those sequences can interleave across instances
    /// and lose updates.
    static let queuesLock = OSAllocatedUnfairLock<[String: DispatchQueue]>(initialState: [:])

    static func queue(for file: File) -> DispatchQueue {
        queuesLock.withLock { queues in
            if let queue = queues[file.name] {
                return queue
            }

            let queue = DispatchQueue(label: "com.tangem.CachesDirectoryStorage_\(file.name)", attributes: .concurrent)
            queues[file.name] = queue
            return queue
        }
    }
}

// MARK: - Public API

public extension CachesDirectoryStorage {
    func value<T>() throws -> T where T: Decodable {
        try queue.sync { try readValue() }
    }

    /// Prefer over the synchronous `value()` when called on the main thread.
    func value<T>() async throws -> T where T: Decodable {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    continuation.resume(returning: try readValue())
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Save the value in asynchronous fashion, providing a completion handler for error handling.
    func store<T>(value: T, completion: ((_ error: Error?) -> Void)? = nil) where T: Encodable {
        queue.async(flags: .barrier) {
            do {
                let data = try encoder.encode(value)
                try writeToFile(data: data)
                completion?(nil)
            } catch {
                completion?(error)
            }
        }
    }

    /// Save the value in synchronous fashion, throwing errors if any.
    func storeAndWait<T>(value: T) throws where T: Encodable {
        try queue.sync(flags: .barrier) {
            let data = try encoder.encode(value)
            try writeToFile(data: data)
        }
    }

    /// Atomically reads the current value (or `defaultValue` if absent), lets `mutate` transform it, and writes
    /// the result back — the whole sequence runs as a single unit on the storage's serial-for-writes queue.
    /// Prefer this over a separate `value()` + `store(value:)` pair whenever the new value depends on the current
    /// one: separate calls race across concurrent callers (including other `CachesDirectoryStorage` instances
    /// backed by the same `file`) and can silently lose one caller's update.
    func modify<T>(defaultValue: T, _ mutate: @escaping (inout T) -> Void) where T: Codable {
        queue.async(flags: .barrier) {
            var value: T = (try? readValue()) ?? defaultValue
            mutate(&value)

            guard let data = try? encoder.encode(value) else {
                return
            }

            try? writeToFile(data: data)
        }
    }
}

// MARK: - Private implementation

private extension CachesDirectoryStorage {
    func readValue<T>() throws -> T where T: Decodable {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw StorageError.fileNotFound
        }

        let data = try Data(contentsOf: fileURL)
        return try decoder.decode(T.self, from: data)
    }

    func writeToFile(data: Data) throws {
        guard
            fileManager.fileExists(atPath: fileURL.path)
        else {
            fileManager.createFile(atPath: fileURL.path, contents: data)
            return
        }

        try data.write(to: fileURL, options: Data.WritingOptions.atomic)
    }
}

// MARK: - Auxiliary types

public extension CachesDirectoryStorage {
    protocol File {
        var name: String { get }
    }

    enum StorageError: Error {
        case fileNotFound
    }
}
