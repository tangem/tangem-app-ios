//
//  TokenItem.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import struct TangemSdk.DerivationPath

enum TokenItem: Hashable {
    case blockchain(Blockchain)
    case token(Token, Blockchain)

    var isBlockchain: Bool { token == nil }
    
    var isToken: Bool { token != nil }
    
    var id: String? {
        switch self {
        case .token(let token, _):
            return token.id
        case .blockchain(let blockchain):
            return blockchain.id
        }
    }
    
    var blockchain: Blockchain {
        switch self {
        case .token(_, let blockchain):
            return blockchain
        case .blockchain(let blockchain):
            return blockchain
        }
    }
    
    var amountType: Amount.AmountType {
        switch self {
        case .token(let token, _):
            return .token(value: token)
        case .blockchain:
            return .coin
        }
    }
    
    func getDefaultBlockchainNetwork(for style: DerivationStyle) -> BlockchainNetwork {
        let path = blockchain.derivationPath(for: style)
        return .init(blockchain, derivationPath: path)
    }
    
    var token: Token? {
        switch self {
        case .token(let token, _):
            return token
        default:
            return nil
        }
    }
    
    var name: String {
        switch self {
        case .token(let token, _):
            return token.name
        case .blockchain(let blockchain):
            return blockchain.displayName
        }
    }
    
    var contractName: String? {
        switch self {
        case .token:
            return blockchain.tokenStandardName
        case .blockchain:
            return "MAIN"
        }
    }
    
    var symbol: String {
        switch self {
        case .token(let token, _):
            return token.symbol
        case .blockchain(let blockchain):
            return blockchain.currencySymbol
        }
    }
    
    var contractAddress: String? {
        token?.contractAddress
    }
}
