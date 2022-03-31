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
    
    var blockchain: Blockchain {
        switch self {
        case .token(_, let blockchain):
            return blockchain
        case .blockchain(let blockchain):
            return blockchain
        }
    }
    
    func derivationPath(for batchId: String) -> DerivationPath? {
        blockchain.derivationPath(for: .init(with: batchId))
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
            switch blockchain {
            case .binance: return "BEP2"
            case .bsc: return "BEP20"
            case .ethereum: return "ERC20"
            default:
                return nil
            }
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
    
    var amountType: Amount.AmountType {
        switch self {
        case .token(let token, _):
            return .token(value: token)
        case .blockchain:
            return .coin
        }
    }
}
