//
//  TokensPersistentService.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

typealias TokenManager = TokensLoader & TokensPersistenceService

protocol TokensLoader: class {
    func loadTokens(for cardId: String, blockchainSymbol: String) -> [Token]
}

protocol TokensPersistenceService: class {
    var savedTokens: [Token] { get }
    func addToken(_ token: Token)
    func removeToken(_ token: Token)
}

class TokenManagerFactory {
    static func manager() -> TokenManager {
        do {
            return try ICloudTokensService()
        } catch {
            print("⚠️ Failed to instantiate iCloud tokens service. Reason:", error, "⚠️")
        }
        return UserDefaultsTokensService()
    }
}

class UserDefaultsTokensService: TokenManager {
    
    private(set) var savedTokens: [Token] = []
    
    private var tokens: [Token] = [] {
        didSet {
            savedTokens = tokens
            let data = try! jsonEncoder.encode(tokens)
            userDefaults.set(data, forKey: key)
        }
    }
    
    private let userDefaults: UserDefaults = .standard
    private let jsonEncoder: JSONEncoder = .init()
    private let jsonDecoder: JSONDecoder = .init()
    private let tokensPrefix = "tokens_for_"
    private var key: String { tokensPrefix + blockchainName + "_" + cardId }
    
    private var blockchainName = ""
    private var cardId: String = ""
    
    fileprivate init() {}
    
    func loadTokens(for cardId: String, blockchainSymbol: String) -> [Token] {
        var tokens = self.tokens
        
        self.cardId = cardId
        self.blockchainName = blockchainSymbol.lowercased()
        
        if !cardId.isEmpty, let data = userDefaults.data(forKey: key) {
            tokens = (try? jsonDecoder.decode([Token].self, from: data)) ?? []
        }
        self.tokens = tokens
        
        return tokens
    }
    
    func addToken(_ token: Token) {
        if tokens.contains(token) { return }
        
        tokens.append(token)
    }
    
    func removeToken(_ token: Token) {
        guard let index = tokens.firstIndex(of: token) else { return }
        
        tokens.remove(at: index)
    }
}

class ICloudTokensService: TokenManager {
    
    private let fileManager = FileManager.default
    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder = JSONDecoder()
    private let documentsFolderName = "Documents"
    private let fileName = "tokens_"
    private let documentType = "json"
    
    private var blockchainName = ""
    private var cardId: String = ""
    
    private(set) var savedTokens = [Token]()
    
    private var containerUrl: URL? {
        fileManager.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent(documentsFolderName)
    }
    
    private var folderPath: URL? {
        blockchainName.isEmpty ? containerUrl : containerUrl?.appendingPathComponent(blockchainName)
    }
    
    private var documentPath: URL {
        return folderPath?.appendingPathComponent(fileName + cardId).appendingPathExtension(documentType) ?? URL(string: "")!
    }
    
    fileprivate init() throws {
        guard let url = self.containerUrl else {
            throw TapError.iCloudNotAvailable
        }
        if !fileManager.fileExists(atPath: url.path, isDirectory: nil) {
            do {
                try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            }
            catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func loadTokens(for cardId: String, blockchainSymbol: String) -> [Token] {
        self.cardId = cardId
        self.blockchainName = blockchainSymbol.lowercased()
        guard fileManager.fileExists(atPath: documentPath.path) else {
            savedTokens = []
            return []
        }
        
        var tokens: [Token] = []
        do {
            let data = try Data(contentsOf: documentPath)
            tokens = try jsonDecoder.decode([Token].self, from: data)
        } catch {
            print("Failed to receive tokens from iCloud. Reason:", error)
        }
        
        self.savedTokens = tokens
        
        return tokens
    }
    
    func addToken(_ token: Token) {
        if savedTokens.contains(token) { return }
        
        savedTokens.append(token)
        saveTokens()
    }
    
    func removeToken(_ token: Token) {
        guard let index = savedTokens.firstIndex(of: token) else { return }
        
        savedTokens.remove(at: index)
        saveTokens()
    }
    
    private func saveTokens() {
        if let folderUrl = folderPath, !fileManager.fileExists(atPath: folderUrl.path, isDirectory: nil) {
            try? fileManager.createDirectory(at: folderUrl, withIntermediateDirectories: true, attributes: nil)
        }
        if !fileManager.fileExists(atPath: documentPath.path) {
            fileManager.createFile(atPath: documentPath.path, contents: nil, attributes: [:])
        }
        
        let data = try! jsonEncoder.encode(savedTokens)
        do {
            try data.write(to: documentPath)
        } catch {
            print("Faield to write tokens to iCloud storage. Reason:", error)
        }
    }
}
