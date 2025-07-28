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
        return transaction.count >= Constants.transactionSizeForALTRely ? .alt : .default
    }
}

extension SolanaWalletConnectTransactionRely {
    /**
     /// Maximum APDU payload size in bytes.
     ///
     /// The full APDU message can be up to **1040 bytes**, but available payload space
     /// is reduced by the derivation path and optional fields (e.g. `PIN2`).
     ///
     /// ### Examples:
     /// - Solana path `m/44'/501'/0'` (3 levels × 4 bytes = 12 bytes)
     ///   → payload = `1040 - 12 = 930` bytes
     ///
     /// - Removing `PIN2` (normally adds 34 bytes: 2-byte TLV tag + 32-byte value)
     ///   → payload increases by **34 bytes**
     ///
     /// ### Formula:
     /// ```swift
     /// maxPayload = 1040 - (derivationDepth * 4) - optionalFieldBytes
     /// ```
     ///
     /// Use this constant for reference in payload building logic.
     */
    enum Constants {
        /// Represents the practical APDU payload limit after accounting for derivation path overhead.
        static let transactionSizeForALTRely: Int = 930
    }
}
