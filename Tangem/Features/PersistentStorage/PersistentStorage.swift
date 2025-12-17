//
//  PersistentStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

class PersistentStorage {
    private let documentType = "json"

    private lazy var encryptionUtility = FileEncryptionUtility()

    private var fileManager: FileManager { FileManager.default }

    private var containerUrl: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    deinit {
        AppLogger.debug(self)
    }

    private func documentPath(for key: String) -> URL {
        containerUrl.appendingPathComponent(key).appendingPathExtension(documentType)
    }

    private func encryptAndWriteToDocuments(_ data: Data, at path: inout URL, options: Data.WritingOptions) throws {
        let encrypted = try encryptionUtility.encryptData(data)
        try encrypted.write(to: path, options: options)
        var fileValues = URLResourceValues()
        fileValues.isExcludedFromBackup = true
        try path.setResourceValues(fileValues)
    }

    private func createDirectory() {
        if !fileManager.fileExists(atPath: containerUrl.path, isDirectory: nil) {
            do {
                try fileManager.createDirectory(at: containerUrl, withIntermediateDirectories: true, attributes: nil)
            } catch {
                AppLogger.error(error: error)
            }
        }
    }
}

extension PersistentStorage: PersistentStorageProtocol {
    func value<T: Decodable>(for key: PersistentStorageKey) throws -> T? {
        let documentPath = documentPath(for: key.path)
        if fileManager.fileExists(atPath: documentPath.path) {
            let data = try Data(contentsOf: documentPath)
            let decryptedData = try encryptionUtility.decryptData(data)
            return try JSONDecoder().decode(T.self, from: decryptedData)
        }

        return nil
    }

    func store<T: Encodable>(value: T, for key: PersistentStorageKey) throws {
        var documentPath = documentPath(for: key.path)
        createDirectory()
        let data = try JSONEncoder().encode(value)
        var options: Data.WritingOptions = [.atomic]
        if key.shouldEnableCompleteFileProtection {
            options.insert(.completeFileProtection)
        }
        try encryptAndWriteToDocuments(data, at: &documentPath, options: options)
    }
}
