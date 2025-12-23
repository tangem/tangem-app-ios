//
//  StoredCryptoAccount+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - Convenience extensions

extension StoredCryptoAccount {
    init(
        config: CryptoAccountPersistentConfig,
        tokenListAppearance: CryptoAccountPersistentConfig.TokenListAppearance,
        tokens: [StoredCryptoAccount.Token] = []
    ) {
        self.init(
            derivationIndex: config.derivationIndex,
            name: config.name,
            icon: .init(iconName: config.iconName, iconColor: config.iconColor),
            tokens: tokens,
            grouping: tokenListAppearance.grouping,
            sorting: tokenListAppearance.sorting
        )
    }

    func withTokens(_ newTokens: [StoredCryptoAccount.Token]) -> Self {
        return StoredCryptoAccount(
            derivationIndex: derivationIndex,
            name: name,
            icon: icon,
            tokens: newTokens,
            grouping: grouping,
            sorting: sorting
        )
    }

    func with(sorting: StoredCryptoAccount.Sorting, grouping: StoredCryptoAccount.Grouping) -> Self {
        return StoredCryptoAccount(
            derivationIndex: derivationIndex,
            name: name,
            icon: icon,
            tokens: tokens,
            grouping: grouping,
            sorting: sorting
        )
    }
}

extension StoredCryptoAccount.Token {
    var isToken: Bool { contractAddress != nil }

    // [REDACTED_TODO_COMMENT]
    var coinId: String? {
        switch blockchainNetwork {
        case .known(let blockchainNetwork):
            return contractAddress == nil ? blockchainNetwork.blockchain.coinId : id
        case .unknown:
            return nil
        }
    }

    var walletModelId: WalletModelId? {
        guard let tokenItem = toTokenItem() else {
            return nil
        }

        return WalletModelId(tokenItem: tokenItem)
    }
}

extension StoredCryptoAccount.Token.BlockchainNetworkContainer {
    /// `known` means that the blockchain network is known and supported by current client version.
    var knownValue: BlockchainNetwork? {
        switch self {
        case .known(let blockchainNetwork):
            return blockchainNetwork
        case .unknown:
            return nil
        }
    }
}
