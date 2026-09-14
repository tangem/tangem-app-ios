//
//  PolymarketWithdrawSourceWalletsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

/// The withdraw source selector: the prediction account and nothing else. The account holds one token, so
/// the row set never changes, while its balance stays live through the account's own balance provider.
struct PolymarketWithdrawSourceWalletsProvider: TokenSelectorWalletsProvider {
    let userWalletInfo: UserWalletInfo
    let source: PolymarketWithdrawSource

    var wallets: [TokenSelectorWallet] {
        [
            TokenSelectorWallet(
                wallet: userWalletInfo,
                accounts: .single(makePolymarketAccountSection())
            ),
        ]
    }
}

// MARK: - The prediction account section

private extension PolymarketWithdrawSourceWalletsProvider {
    func makePolymarketAccountSection() -> TokenSelectorAccount {
        let item = TokenSelectorItem(userWalletInfo: userWalletInfo, kind: .polymarket(source))

        return TokenSelectorAccount(
            account: source.accountModel,
            itemsProvider: StaticTokenSelectorItemsProvider(items: [item]),
            rateProvider: nil
        )
    }
}
