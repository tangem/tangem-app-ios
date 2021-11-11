//
//  PersistentStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

enum PersistentStorageKey {
    case cards
    case wallets(cid: String)
    
    var path: String {
        switch self {
        case .cards:
            return "scanned_cards"
        case .wallets(let cid):
            return "wallets_\(cid)"
        }
    }
}

class PersistentStorage {
    private let documentsFolderName = "Documents"
    private let documentType = "json"
    
    private let encryptionUtility: FileEncryptionUtility
    
    private var fileManager: FileManager {
        get { FileManager.default }
    }
    
    private var cloudContainerUrl: URL? {
        fileManager.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent(documentsFolderName)
    }
    
    private var containerUrl: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    deinit {
        print("PersistentStorage deinit")
    }
    
    init(encryptionUtility: FileEncryptionUtility) {
        self.encryptionUtility = encryptionUtility
        transferFiles()
    }
    
    func value<T: Codable>(for key: PersistentStorageKey) throws -> T? {
        var data: Data?
        let decoder = JSONDecoder()
        
        if let cloudFilePath = cloudContainerUrl?.appendingPathComponent(key.path).appendingPathExtension(documentType),
           fileManager.fileExists(atPath: cloudFilePath.path) {
            
            data = try Data(contentsOf: cloudFilePath)
            
            if let unwrappedData = data {
                let decoded = try decoder.decode(T.self, from: unwrappedData)
                try store(value: decoded, for: key)
                try fileManager.removeItem(at: cloudFilePath)
                return decoded
            }
        }
        
        let documentPath = self.documentPath(for: key.path)
        if fileManager.fileExists(atPath: documentPath.path) {
            let data = try Data(contentsOf: documentPath)
            let decryptedData = try encryptionUtility.decryptData(data)
            return try JSONDecoder().decode(T.self, from: decryptedData)
        }
        
        return nil
    }
    
    func store<T:Encodable>(value: T, for key: PersistentStorageKey) throws {
        var documentPath = self.documentPath(for: key.path)
        createDirectory()
        let data = try JSONEncoder().encode(value)
        try encryptAndWriteToDocuments(data, at: &documentPath)
    }
    
    private func transferFiles() {
        guard let cloudContainerUrl = self.cloudContainerUrl else {
            return
        }
        
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: cloudContainerUrl.path)
            guard contents.count > 0 else {
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
