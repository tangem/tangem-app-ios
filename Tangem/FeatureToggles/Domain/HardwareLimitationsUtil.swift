//
//  HardwareLimitationsUtil.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct HardwareLimitationsUtil {
    private let config: UserWalletConfig
    private let solanaTransactionHelper = SolanaTransactionHelper()

    init(config: UserWalletConfig) {
        self.config = config
    }

    func canAdd(_ tokenItem: TokenItem) -> Bool {
        if tokenItem.hasLongHashes(for: .send), !config.hasFeature(.longHashes) {
            return false
        }

        return true
    }

    func getSendLimitations(_ tokenItem: TokenItem) -> SendLimitation {
        guard config.hasFeature(.signing) else {
            return .oldCard
        }

        if tokenItem.hasLongHashes(for: .send), !config.hasFeature(.longHashes) {
            return .longHashes
        }

        if config.hasFeature(.nfcInteraction), !tokenItem.canBeSentOnPoorNFCQualityDevice,
           NFCUtils.isPoorNfcQualityDevice {
            return .oldDevice
        }

        return .none
    }

    /// - Note: Some (but not limited to) examples of contract interactions are: staking, working with NFTs, etc.
    /// - Warning: Even though sending network tokens is also typically performed via contract interactions -
    /// such check must be done using the `canSend(_:)` method above.
    func canPerformContractInteractions(with tokenItem: TokenItem) -> Bool {
        if tokenItem.hasLongHashes(for: .contractInteractions), !config.hasFeature(.longHashes) {
            return false
        }

        if config.hasFeature(.nfcInteraction), !tokenItem.canPerformContractInteractionsOnPoorNFCQualityDevice,
           NFCUtils.isPoorNfcQualityDevice {
            return false
        }

        return true
    }

    func canHandleTransaction(_ tokenItem: TokenItem, transaction: Data) throws -> Bool {
        guard config.hasFeature(.transactionPayloadLimit) else {
            return true
        }

        switch tokenItem.blockchain {
        case .solana:
            let size = try solanaTransactionHelper.transactionSize(withSignaturePlaceholders: transaction)
            switch size {
            case .default:
                return true
            case .long:
                return false
            }
        default:
            return true
        }
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

extension HardwareLimitationsUtil {
    enum SendLimitation {
        case oldCard
        case longHashes
        case oldDevice
        case none
    }
}
