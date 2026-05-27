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

    #if ALPHA || BETA || INTERNAL || DEBUG
    // No-op
    #else
    // [REDACTED_TODO_COMMENT]
    @available(iOS, deprecated: 100000.0, message: "For troubleshooting purposes on production builds only ([REDACTED_INFO])")
    static func dummy(withDerivationIndex derivationIndex: Int) -> Self {
        let icon = AccountModel.CompositeIcon(name: .allCases[0], color: .allCases[0])
        let config = CryptoAccountPersistentConfig(derivationIndex: derivationIndex, name: nil, icon: icon)

        return StoredCryptoAccount(config: config, tokenListAppearance: .default)
    }
    #endif // ALPHA || BETA || INTERNAL || DEBUG

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

    var walletModelId: WalletModelId? {
        guard let tokenItem = toTokenItem() else {
            return nil
        }

        return WalletModelId(tokenItem: tokenItem)
    }

    func with(blockchainNetwork: BlockchainNetworkContainer) -> Self {
        StoredCryptoAccount.Token(
            id: id,
            name: name,
            symbol: symbol,
            decimalCount: decimalCount,
            blockchainNetwork: blockchainNetwork,
            contractAddress: contractAddress
        )
    }
}

extension StoredCryptoAccount.Token.BlockchainNetworkContainer {
    /// `known` means that the blockchain network is known and supported by current client version.
    var knownValue: StoredCryptoAccount.Token.StoredBlockchainNetwork? {
        switch self {
        case .known(let blockchainNetwork):
            return blockchainNetwork
        case .unknown:
            return nil
        }
    }
}
