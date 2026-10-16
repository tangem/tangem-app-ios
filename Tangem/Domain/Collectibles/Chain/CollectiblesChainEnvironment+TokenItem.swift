//
//  CollectiblesChainEnvironment+TokenItem.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemCollectibles

extension CollectiblesChainEnvironment {
    /// Quoting and formatting vehicle for the vault's balance, not an on-chain identity: the mint a transfer
    /// settles against is always the one the config names. `usd-coin` is network-agnostic on purpose, so the
    /// devnet test token is priced by the quote service all the same.
    ///
    /// The cold owner's derivation path is what keeps the balance cache entry off an ordinary USDC wallet model's.
    static var usdcTokenItem: TokenItem {
        usdcTokenItem(mint: Constants.usdcMintAddress)
    }

    static func usdcTokenItem(mint: String) -> TokenItem {
        TokenItem.token(
            Token(
                name: Constants.usdcName,
                symbol: Constants.usdcSymbol,
                contractAddress: mint,
                decimalCount: Constants.usdcDecimalCount,
                id: Constants.usdcCurrencyId,
                metadata: .fungibleTokenMetadata
            ),
            BlockchainNetwork(blockchain, derivationPath: CollectiblesAccountKeyPath.derivationPath)
        )
    }
}

// MARK: - Constants

private extension CollectiblesChainEnvironment {
    enum Constants {
        static let usdcName = "USD Coin"
        static let usdcSymbol = "USDC"
        // [REDACTED_TODO_COMMENT]
        static let usdcMintAddress = "Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr"
        static let usdcDecimalCount = 6
        static let usdcCurrencyId = "usd-coin"
    }
}
