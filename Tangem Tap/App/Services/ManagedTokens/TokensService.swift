//
//  TokensService.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk
import Combine

class TokensServiceFactory {
    static func makeService(for card: Card, persistenceService: TokensPersistenceController, tokenWalletManager: TokenManager?) -> TokensService? {
        guard
            let blockchain = card.blockchain,
            let manager = tokenWalletManager
        else { return nil }
        
        switch blockchain {
        case .ethereum: return DefaultTokensService(provider: ERC20TokenProvider.instance, persistenceService: persistenceService, manager: manager)
        default: return nil
        }
    }
}

protocol TokensService {
    var cardTokens: [Token] { get }
    var availableTokens: [Token] { get }
    func addToken(_ token: Token) -> AnyPublisher<Amount, Error>
    func removeToken(_ token: Token)
}

class DefaultTokensService {
    
    private static var service: DefaultTokensService!
    
    private let provider: TokenProvider
    private let persistenceService: TokensPersistenceController
    private let manager: TokenManager
    
    fileprivate init(provider: TokenProvider, persistenceService: TokensPersistenceController, manager: TokenManager) {
        self.provider = provider
        self.persistenceService = persistenceService
        self.manager = manager
    }
}

extension DefaultTokensService: TokensService {
    
    var cardTokens: [Token] {
        persistenceService.savedTokens
    }
    
    var availableTokens: [Token] {
        provider.tokens.filter { !persistenceService.savedTokens.contains($0) }
    }
    
    func addToken(_ token: Token) -> AnyPublisher<Amount, Error> {
        persistenceService.addToken(token)
        return manager.addToken(token)
    }
    
    func removeToken(_ token: Token) {
        persistenceService.removeToken(token)
        manager.removeToken(token)
    }
}
