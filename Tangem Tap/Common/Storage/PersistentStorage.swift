//
//  PersistentStorage.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

enum PersistentStorageKey {
    case wallets(cid: String)
    
    var path: String {
        switch self {
        case .wallets(let cid):
            return "wallets_\(cid)"
        }
    }
}

class PersistentStorage {
    private let documentsFolderName = "Documents"
    private let documentType = "json"
    
    private var fileManager: FileManager {
        get { FileManager.default }
    }
    
    private var containerUrl: URL {
        fileManager.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent(documentsFolderName) ??
            fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    func value<T: Decodable>(for key: PersistentStorageKey) throws -> T? {
        let documentPath = self.documentPath(for: key.path)
        if fileManager.fileExists(atPath: documentPath.path) {
            let data = try Data(contentsOf: documentPath)
            return try JSONDecoder().decode(T.self, from: data)
        }
        
        return nil
    }
    
    func store<T:Encodable>(value: T, for key: PersistentStorageKey) throws {
        let documentPath = self.documentPath(for: key.path)
        createDirectory()
        
        let data = try JSONEncoder().encode(value)
        try data.write(to: documentPath)
    }
    
    private func documentPath(for key: String) -> URL {
        return containerUrl.appendingPathComponent(key).appendingPathExtension(documentType)
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
