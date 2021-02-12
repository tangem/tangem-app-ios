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

protocol TokensService {
    var cardTokens: [Token] { get }
    var availableTokens: [Token] { get }
    func addToken(_ token: Token)
    func removeToken(_ token: Token)
}

class ERC20TokensProvider {
    
    private(set) var tokens: [Token] = []
    
    init() {
        guard let url = Bundle.main.url(forResource: "erc20tokens", withExtension: "json") else {
            print("Failed to find erc 20 tokens json file")
            return
        }
        do {
            let data = try Data(contentsOf: url)
            tokens = try JSONDecoder().decode([Token].self, from: data)
        } catch {
            print("Failed to fetch erc20 tokens from \(url). Reason: \(error)")
        }
        
    }
    
}

class DefaultTokensService: TokensService {
    var cardTokens: [Token] { [] }
    var availableTokens: [Token] { [] }
    func addToken(_ token: Token) { }
    func removeToken(_ token: Token) { }
}

class EthereumTokensService {
    
    private static var service: EthereumTokensService!
    
    static func instance(tokenService: TokensPersistenceService) -> EthereumTokensService {
        if service == nil || service.tokenPersistenceService === tokenService {
            service = EthereumTokensService(tokensService: tokenService)
        }
        return service
    }
    
    private let tokenProvider: ERC20TokensProvider
    private let tokenPersistenceService: TokensPersistenceService
    
    private init(tokensService: TokensPersistenceService) {
        tokenProvider = ERC20TokensProvider()
        tokenPersistenceService = tokensService
    }
}

extension EthereumTokensService: TokensService {
    
    var cardTokens: [Token] {
        tokenPersistenceService.savedTokens
    }
    
    var availableTokens: [Token] {
        tokenProvider.tokens.filter { !tokenPersistenceService.savedTokens.contains($0) }
    }
    
    func addToken(_ token: Token) {
        tokenPersistenceService.addToken(token)
    }
    
    func removeToken(_ token: Token) {
        tokenPersistenceService.removeToken(token)
    }
}
