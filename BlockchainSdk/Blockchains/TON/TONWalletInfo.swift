//
//  TONWalletINfo.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

/// Union for use logic info TON wallet
public struct TONWalletInfo {
    
    /// Wallet balance
    let balance: Decimal
    
    /// Sequence number last transaction
    let sequenceNumber: Int
    
    /// Wallet availability
    let isAvailable: Bool
    
    let tokensInfo: [Token: TokenInfo]
    
    struct TokenInfo {
        let jettonWalletAddress: String
        let balance: Decimal
    }
}
