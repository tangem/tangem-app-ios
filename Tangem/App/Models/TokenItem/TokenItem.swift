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

enum TokenItem: Hashable, Codable {
    case blockchain(Blockchain)
    case token(Token, Blockchain)

    var isBlockchain: Bool { token == nil }

    var isToken: Bool { token != nil }

    var id: String? {
        switch self {
        case .token(let token, _):
            return token.id
        case .blockchain(let blockchain):
            return blockchain.coinId
        }
    }

    var currencyId: String? {
        switch self {
        case .token(let token, _):
            return token.id
        case .blockchain(let blockchain):
            return blockchain.currencyId
        }
    }

    var networkId: String {
        return blockchain.networkId
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

    var currencySymbol: String {
        switch self {
        case .token(let token, _):
            return token.symbol
        case .blockchain(let blockchain):
            return blockchain.currencySymbol
        }
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
            return blockchain.tokenTypeName
        case .blockchain:
            return "MAIN"
        }
    }

    var contractAddress: String? {
        token?.contractAddress
    }

    var networkName: String {
        blockchain.displayName
    }

    var decimalCount: Int {
        switch self {
        case .token(let token, _):
            return token.decimalCount
        case .blockchain(let blockchain):
            return blockchain.decimalCount
        }
    }

    var feeDecimalCount: Int {
        switch blockchain.feePaidCurrency {
        case .coin:
            blockchain.decimalCount
        case .token(let feeToken):
            feeToken.decimalCount
        case .sameCurrency:
            decimalCount
        }
    }
}
