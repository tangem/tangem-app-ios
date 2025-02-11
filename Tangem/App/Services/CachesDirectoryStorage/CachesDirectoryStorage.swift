//
//  CachesDirectoryStorage.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct CachesDirectoryStorage {
    private let file: File
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    // Internal

    private let queue: DispatchQueue = .init(label: "com.tangem.CachesDirectoryStorage")
    private let fileManager: FileManager = .default
    private var fileURL: URL {
        fileManager
            .urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(file.name)
            .appendingPathExtension("json")
    }

    init(file: File, encoder: JSONEncoder = .init(), decoder: JSONDecoder = .init()) {
        self.file = file
        self.encoder = encoder
        self.decoder = decoder
    }
}

extension CachesDirectoryStorage {
    func value<T>() throws -> T where T: Decodable {
        try queue.sync {
            let data = try Data(contentsOf: fileURL)
            let value = try decoder.decode(T.self, from: data)
            return value
        }
    }

    func store<T>(value: T) throws where T: Encodable {
        try queue.sync {
            let data = try encoder.encode(value)
            try writeToFile(data: data)
        }
    }
}

private extension CachesDirectoryStorage {
    func writeToFile(data: Data) throws {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            fileManager.createFile(atPath: fileURL.path, contents: data)
            return
        }

        try data.write(to: fileURL, options: Data.WritingOptions.atomic)
    }
}

extension CachesDirectoryStorage {
    enum File: String {
        case cachedBalances
        case cachedQuotes

        var name: String {
            switch self {
            case .cachedBalances:
                return "cached_balances"
            case .cachedQuotes:
                return "cached_quotes"
            }
        }
    }
}
