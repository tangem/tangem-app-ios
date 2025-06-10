//
//  AppUtils.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct AppUtils {
    func hasLongHashesForSend(_ tokenItem: TokenItem) -> Bool {
        return tokenItem.hasLongHashes(for: .send)
    }

    /// - Note: Some (but not limited to) examples of contract interactions are: staking, working with NFTs, etc.
    /// - Warning: Even though sending network tokens is also typically performed via contract interactions -
    /// such check must be done using the `hasLongHashesForSend(_:)` method above.
    func hasLongHashesForContractInteractions(_ tokenItem: TokenItem) -> Bool {
        return tokenItem.hasLongHashes(for: .contractInteractions)
    }

    func canSend(_ tokenItem: TokenItem) -> Bool {
        guard NFCUtils.isPoorNfcQualityDevice else {
            return true
        }

        return tokenItem.canBeSentOnPoorNFCQualityDevice
    }

    /// - Note: Some (but not limited to) examples of contract interactions are: staking, working with NFTs, etc.
    /// - Warning: Even though sending network tokens is also typically performed via contract interactions -
    /// such check must be done using the `canSend(_:)` method above.
    func canPerformContractInteractions(with tokenItem: TokenItem) -> Bool {
        guard NFCUtils.isPoorNfcQualityDevice else {
            return true
        }

        return tokenItem.canPerformContractInteractionsOnPoorNFCQualityDevice
    }
}

// MARK: - Private implementation

private extension TokenItem {
    enum LongHashesPurpose {
        case send
        case contractInteractions
    }

    /// We can't sign transactions at legacy devices for these blockchains
    var canBeSentOnPoorNFCQualityDevice: Bool {
        switch blockchain {
        case .solana:
            return !isToken
        case .chia, .aptos, .algorand:
            return false
        default:
            return true
        }
    }

    var canPerformContractInteractionsOnPoorNFCQualityDevice: Bool {
        switch blockchain {
        case .solana:
            return false
        default:
            return true
        }
    }

    /// We can't sign hashes on firmware prior 4.52
    func hasLongHashes(for purpose: LongHashesPurpose) -> Bool {
        switch (blockchain, purpose) {
        case (.solana, .send):
            return isToken
        case (.solana, .contractInteractions):
            return true
        default:
            return false
        }
    }
}
