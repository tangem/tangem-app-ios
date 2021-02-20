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

typealias TokenPersistenceService = TokensLoader & TokensPersistenceController

protocol TokensLoader: class {
    func loadTokens(for cardId: String, blockchainSymbol: String) -> [Token]
}

protocol TokensPersistenceController: class {
    var savedTokens: [Token] { get }
    func addToken(_ token: Token)
    func removeToken(_ token: Token)
}

class ICloudTokenPersistenceService: TokenPersistenceService {
    
    private let fileManager = FileManager.default
    private let documentsFolderName = "Documents"
    private let fileName = "tokens_"
    private let documentType = "json"
    
    private var blockchainName = ""
    private var cardId: String = ""
    
    private(set) var savedTokens = [Token]()
    
    private var containerUrl: URL {
        fileManager.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent(documentsFolderName) ??
            fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private var folderPath: URL {
        blockchainName.isEmpty ? containerUrl : containerUrl.appendingPathComponent(blockchainName)
    }
    
    private var documentPath: URL {
        return folderPath.appendingPathComponent(fileName + cardId).appendingPathExtension(documentType)
    }
    
    init() {
        if !fileManager.fileExists(atPath: containerUrl.path, isDirectory: nil) {
            do {
                try fileManager.createDirectory(at: containerUrl, withIntermediateDirectories: true, attributes: nil)
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
            tokens = try JsonUtils.readJsonData(data, type: [Token].self)
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
        if !fileManager.fileExists(atPath: folderPath.path, isDirectory: nil) {
            try? fileManager.createDirectory(at: folderPath, withIntermediateDirectories: true, attributes: nil)
        }
        if !fileManager.fileExists(atPath: documentPath.path) {
            fileManager.createFile(atPath: documentPath.path, contents: nil, attributes: [:])
        }
        
        do {
            let data = try JsonUtils.writeJsonToData(savedTokens)
            try data.write(to: documentPath)
        } catch {
            print("Faield to write tokens to iCloud storage. Reason:", error)
        }
    }
}
