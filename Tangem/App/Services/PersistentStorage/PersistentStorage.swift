//
//  PersistentStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

class PersistentStorage {
    private let documentsFolderName = "Documents"
    private let documentType = "json"

    private var fileManager: FileManager {
        get { FileManager.default }
    }

    private var cloudContainerUrl: URL? {
        fileManager.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent(documentsFolderName)
    }

    private var containerUrl: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private lazy var encryptionUtility: FileEncryptionUtility = .init()

    init() {
        transferFiles()
        clean()
    }

    deinit {
        print("PersistentStorage deinit")
    }

    private func transferFiles() {
        guard let cloudContainerUrl = self.cloudContainerUrl else {
            return
        }

        do {
            let contents = try fileManager.contentsOfDirectory(atPath: cloudContainerUrl.path)
            guard !contents.isEmpty else {
                return
            }

            contents.forEach {
                let cloudPath = cloudContainerUrl.appendingPathComponent($0)

                guard fileManager.fileExists(atPath: cloudPath.path) else { return }

                do {
                    var documentPath = containerUrl.appendingPathComponent($0)
                    let data = try Data(contentsOf: cloudPath)
                    try encryptAndWriteToDocuments(data, at: &documentPath)
                    try fileManager.removeItem(at: cloudPath)
                } catch {
                    print("Error for file at path: \(cloudPath). Error description: \(error)")
                }
            }
        } catch {
            print(error)
        }
    }

    private func clean() {
        let key = PersistentStorageKey.cards
        let documentPath = self.documentPath(for: key.path)
        try? fileManager.removeItem(atPath: documentPath.path)
    }

    private func documentPath(for key: String) -> URL {
        containerUrl.appendingPathComponent(key).appendingPathExtension(documentType)
    }

    private func encryptAndWriteToDocuments(_ data: Data, at path: inout URL) throws {
        let encrypted = try encryptionUtility.encryptData(data)
        try encrypted.write(to: path, options: .atomic)
        var fileValues = URLResourceValues()
        fileValues.isExcludedFromBackup = true
        try path.setResourceValues(fileValues)
    }

    private func createDirectory() {
        if !fileManager.fileExists(atPath: containerUrl.path, isDirectory: nil) {
            do {
                try fileManager.createDirectory(at: containerUrl, withIntermediateDirectories: true, attributes: nil)
            }
            catch {
                print(error.localizedDescription)
            }
        }
    }
}

extension PersistentStorage: PersistentStorageProtocol {
    func value<T: Decodable>(for key: PersistentStorageKey) throws -> T? {
        let documentPath = self.documentPath(for: key.path)
        if fileManager.fileExists(atPath: documentPath.path) {
            let data = try Data(contentsOf: documentPath)
            let decryptedData = try encryptionUtility.decryptData(data)
            return try JSONDecoder().decode(T.self, from: decryptedData)
        }

        return nil
    }

    func store<T: Encodable>(value: T, for key: PersistentStorageKey) throws {
        var documentPath = self.documentPath(for: key.path)
        createDirectory()
        let data = try JSONEncoder().encode(value)
        try encryptAndWriteToDocuments(data, at: &documentPath)
    }

    func readAllWallets<T: Decodable>() -> [String: T] {
        var wallets: [String: T] = [:]

        if let contents = try? fileManager.contentsOfDirectory(atPath: containerUrl.path) {
            contents.forEach {
                if $0.contains("wallets_") {
                    let cardId = $0.remove("wallets_").remove(".json")
                    let key: PersistentStorageKey = .wallets(cid: cardId)
                    let documentPath = self.documentPath(for: key.path)
                    if let data = try? Data(contentsOf: documentPath),
                       let decryptedData = try? encryptionUtility.decryptData(data),
                       let decodedData = try? JSONDecoder().decode(T.self, from: decryptedData) {
                        wallets[cardId] = decodedData
                    }
                }
            }
        }

        return wallets
    }
}
