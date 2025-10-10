//
//  SolanaTransactionSizeUtils.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public enum SolanaTransactionSize {
    case `default`
    case long
}

public enum SolanaTransactionSizeUtils {
    public static func size(for transactionData: Data) -> SolanaTransactionSize {
        return transactionData.count >= Constants.supportedTransactionSize ? .long : .default
    }

    /// Maximum APDU payload size in bytes.
    ///
    /// The full APDU packet is **1040 bytes**. Available payload space is calculated by:
    /// 1. Subtracting required service data
    /// 2. Subtracting derivation path size
    ///
    /// ### Formula:
    /// ```swift
    /// maxPayload = 1040 - serviceDataBytes - (derivationDepth * 4)
    /// ```
    ///
    /// ### Example:
    /// - Solana path `m/44'/501'/0'` (3 levels × 4 bytes = 12 bytes)
    /// - Service data varies by wallet type (e.g., Wallet 3 has different overhead)
    ///
    /// Use this constant for reference in payload building logic.
    enum Constants {
        /// Represents the practical APDU payload limit after accounting for service data and derivation path overhead.
        static let supportedTransactionSize: Int = 964
    }
}
