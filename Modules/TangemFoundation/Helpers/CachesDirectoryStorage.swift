//
//  CachesDirectoryStorage.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct CachesDirectoryStorage {
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
        queue = DispatchQueue(label: "com.tangem.CachesDirectoryStorage_\(file.name)", attributes: .concurrent)
    }
}

// MARK: - Public API

public extension CachesDirectoryStorage {
    func value<T>() throws -> T where T: Decodable {
        try queue.sync {
            guard fileManager.fileExists(atPath: fileURL.path) else {
                throw StorageError.fileNotFound
            }

            let data = try Data(contentsOf: fileURL)
            let value = try decoder.decode(T.self, from: data)
            return value
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
}

// MARK: - Private implementation

private extension CachesDirectoryStorage {
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
