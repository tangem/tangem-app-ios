//
//  TokenInfoExtractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct TokenInfoExtractor {
    let type: Amount.AmountType
    let blockchain: Blockchain

    var name: String {
        switch type {
        case .token(let token): return token.name
        default: return blockchain.displayName
        }
    }

    var currencySymbol: String {
        switch type {
        case .token(let token): return token.symbol
        default: return blockchain.currencySymbol
        }
    }

    var networkName: String {
        blockchain.displayName
    }

    var iconViewModel: TokenIconViewModel {
        .init(with: type, blockchain: blockchain)
    }
}
