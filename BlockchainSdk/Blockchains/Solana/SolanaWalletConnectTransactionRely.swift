//
//  SolanaWalletConnectTransactionRely.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public enum SolanaWalletConnectTransactionRely {
    case `default`
    case alt

    public static func rely(transaction: Data) -> SolanaWalletConnectTransactionRely {
        switch SolanaTransactionSizeUtils.size(transaction: transaction) {
        case .default:
            return .default
        case .long:
            return .alt
        }
    }
}
