//
//  CommonTokenItemsRepository.swift
//  Tangem
//
//  Created by Alexander Osokin on 28.02.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import struct TangemSdk.DerivationPath
import Network

class CommonTokenItemsRepository {
    @Injected(\.persistentStorage) var persistanceStorage: PersistentStorageProtocol
    
    private let lockQueue = DispatchQueue(label: "token_items_repo_queue")
    
    init() {
        lockQueue.sync {
            migrate()
        }
    }
    
    deinit {
        print("TokenItemsRepository deinit")
    }
    
    func append(_ blockchains: [Blockchain], for cardId: String, style: DerivationStyle) {
        let networks = blockchains.map {
            BlockchainNetwork($0, derivationPath: $0.derivationPath(for: style))
        }
        
        append(networks, for: cardId)
    }
    
    func append(_ entries: [StorageEntry], for cardId: String) {
        lockQueue.sync {
            var items = fetch(for: cardId)
            var hasAppended: Bool = false
            
            entries.forEach {
                if items.tryAppend(entry: $0) {
                    hasAppended = true
                }
            }
            
            if hasAppended {
                save(items, for: cardId)
            }
        }
    }
    
    func append(_ blockchainNetworks: [BlockchainNetwork], for cardId: String) {
        lockQueue.sync {
            var items = fetch(for: cardId)
            var hasAppended: Bool = false
            
            blockchainNetworks.forEach {
                if items.tryAppend(blockchainNetwork: $0) {
                    hasAppended = true
                }
            }
            
            if hasAppended {
                save(items, for: cardId)
            }
        }
    }
    
    func append(_ tokens: [Token], blockchainNetwork: BlockchainNetwork, for cardId: String) {
        lockQueue.sync {
            var items = fetch(for: cardId)
            var hasAppended: Bool = false
            
            tokens.forEach {
                if items.tryAppend(token: $0, in: blockchainNetwork) {
                    hasAppended = true
                }
            }
            
            if hasAppended {
                save(items, for: cardId)
            }
        }
    }
    
    func remove(_ blockchainNetwork: BlockchainNetwork, for cardId: String) {
        remove([blockchainNetwork], for: cardId)
    }
    
    func remove(_ blockchainNetworks: [BlockchainNetwork], for cardId: String){
        lockQueue.sync {
            var items = fetch(for: cardId)
            var hasRemoved: Bool = false
            
            blockchainNetworks.forEach {
                if items.tryRemove(blockchainNetwork: $0) {
                    hasRemoved = true
                }
            }
            
            if hasRemoved {
                save(items, for: cardId)
            }
        }
    }
    
    func remove(_ token: Token, blockchainNetwork: BlockchainNetwork, for cardId: String) {
        remove([token], blockchainNetwork: blockchainNetwork, for: cardId)
    }
    
    func remove(_ tokens: [Token], blockchainNetwork: BlockchainNetwork, for cardId: String) {
        lockQueue.sync {
            var items = fetch(for: cardId)
            var hasRemoved: Bool = false
            
            tokens.forEach {
                if items.tryRemove(token: $0, in: blockchainNetwork) {
                    hasRemoved = true
                }
            }
            
            if hasRemoved {
                save(items, for: cardId)
            }
        }
    }
    
    func removeAll(for cardId: String) {
        lockQueue.sync {
            save([], for: cardId)
        }
    }
    
    func getItems(for cardId: String) -> [StorageEntry] {
        lockQueue.sync {
            return fetch(for: cardId)
        }
    }
    
    private func migrate() {
        let wallets: [String: [LegacyStorageEntry]] = persistanceStorage.readAllWallets()
        
        guard !wallets.isEmpty else {
            return
        }
        
        wallets.forEach { cardId, oldData in
            let blockchains = Set(oldData.map{ $0.blockchain })
            let tokens = oldData.compactMap { $0.token }
            let groupedTokens = Dictionary(grouping: tokens, by: { $0.blockchain })
            
            let newData: [StorageEntry] = blockchains.map { blockchain in
                let tokens = groupedTokens[blockchain]?.map { $0.newToken } ?? []
                return StorageEntry(blockchainNetwork: BlockchainNetwork(blockchain,
                                                                         derivationPath: blockchain.derivationPath(for: .legacy)),
                                    tokens: tokens)
            }
            
            save(newData, for: cardId)
        }
    }
    
    private func fetch(for cardId: String) -> [StorageEntry] {
        return (try? persistanceStorage.value(for: .wallets(cid: cardId))) ?? []
    }
    
    private func save(_ items: [StorageEntry], for cardId: String) {
        try? persistanceStorage.store(value: items, for: .wallets(cid: cardId))
    }
}

fileprivate extension Array where Element == StorageEntry {
    mutating func tryAppend(entry: Element) -> Bool {
        if let existingIndex = firstIndex(where: { $0.blockchainNetwork == entry.blockchainNetwork }) {
            var appended: Bool = false
            
            entry.tokens.forEach {
                if !self[existingIndex].tokens.contains($0) {
                    self[existingIndex].tokens.append($0)
                    appended = true
                }
            }
            
            return appended
        } else {
            //add new entry
            append(entry)
        }
        
        return true
    }
    
    mutating func tryAppend(token: Token, in blockchainNetwork: BlockchainNetwork) -> Bool {
        if let existingIndex = firstIndex(where: { $0.blockchainNetwork == blockchainNetwork }) {
            if let existingTokenIndex = self[existingIndex].tokens.firstIndex(of: token) {
                if self[existingIndex].tokens[existingTokenIndex].id == nil,
                   token.id != nil {
                    self[existingIndex].tokens[existingTokenIndex] = token //upgrade custom token
                } else {
                    return false //already contains
                }
            } else {
                self[existingIndex].tokens.append(token) //append new token
            }
        } else {
            //create new entry
            let entry = StorageEntry(blockchainNetwork: blockchainNetwork, tokens: [token])
            append(entry)
        }
        
        return true
    }
    
    mutating func tryAppend(blockchainNetwork: BlockchainNetwork) -> Bool {
        if contains(where: { $0.blockchainNetwork == blockchainNetwork }) {
            return false //already contains
        } else {
            //create new entry
            let entry = StorageEntry(blockchainNetwork: blockchainNetwork, tokens: [])
            append(entry)
            return true
        }
    }
    
    mutating func tryRemove(token: Token, in blockchainNetwork: BlockchainNetwork) -> Bool {
        if let existingIndex = firstIndex(where: { $0.blockchainNetwork == blockchainNetwork }) {
            if let tokenIndex = self[existingIndex].tokens.firstIndex(where: { $0 == token }) {
                self[existingIndex].tokens.remove(at: tokenIndex)
                return true
            }
        }
        
        return false
    }
    
    mutating func tryRemove(blockchainNetwork: BlockchainNetwork) -> Bool {
        if let existingIndex = firstIndex(where: { $0.blockchainNetwork == blockchainNetwork }) {
            remove(at: existingIndex)
            return true
        }
        
        return false
    }
}

extension CommonTokenItemsRepository: TokenItemsRepository {
    
}

struct StorageEntry: Codable, Equatable {
    let blockchainNetwork: BlockchainNetwork
    var tokens: [BlockchainSdk.Token]
}

//MARK: - Legacy storage

fileprivate enum LegacyStorageEntry: Codable {
    case blockchain(Blockchain)
    case token(LegacyToken)
    
    var blockchain: Blockchain {
        switch self {
        case .blockchain(let blockchain):
            return blockchain
        case .token(let token):
            return token.blockchain
        }
    }
    
    var token: LegacyToken? {
        switch self {
        case .blockchain:
            return nil
        case .token(let token):
            return token
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let token = try? container.decode(LegacyToken.self) {
            self = .token(token)
            return
        }
        
        if let blockchain = try? container.decode(Blockchain.self) {
            self = .blockchain(blockchain)
            return
        }
        
        if let tokenDto = try? container.decode(LegacyCloudToken.self) {
            let token = LegacyToken(name: tokenDto.name,
                                    symbol: tokenDto.symbol,
                                    contractAddress: tokenDto.contractAddress,
                                    decimalCount: tokenDto.decimalCount,
                                    customIconUrl: tokenDto.customIconUrl,
                                    blockchain: .ethereum(testnet: false))
            self = .token(token)
            return
        }
        
        throw BlockchainSdkError.decodingFailed
    }
}

fileprivate struct LegacyToken: Codable {
    let name: String
    let symbol: String
    let contractAddress: String
    let decimalCount: Int
    let customIconUrl: String?
    let blockchain: Blockchain
    
    var newToken: Token {
        .init(name: name,
              symbol: symbol,
              contractAddress: contractAddress,
              decimalCount: decimalCount,
              customIconUrl: customIconUrl)
    }
}

fileprivate struct LegacyCloudToken: Decodable {
    let name: String
    let symbol: String
    let contractAddress: String
    let decimalCount: Int
    let customIcon: String?
    let customIconUrl: String?
}
