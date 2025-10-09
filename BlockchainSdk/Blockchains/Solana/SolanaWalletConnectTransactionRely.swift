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

    public static func rely(transaction: Data) throws -> SolanaWalletConnectTransactionRely {
        switch try SolanaTransactionSizeUtils().size(for: transaction, isIncludeSignatures: false) {
        case .default:
            return .default
        case .long:
            return .alt
        }
    }
}
