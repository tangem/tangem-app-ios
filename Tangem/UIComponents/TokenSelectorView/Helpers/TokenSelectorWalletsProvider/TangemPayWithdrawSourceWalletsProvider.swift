//
//  TangemPayWithdrawSourceWalletsProvider.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

/// The withdraw source selector: one row per token the payment account holds, in funding
/// priority order. The row set is a static snapshot — the flow resolves the account tokens
/// before it opens — but each row's balance stays live via the account's balance service.
struct TangemPayWithdrawSourceWalletsProvider: TokenSelectorWalletsProvider {
    let userWalletInfo: UserWalletInfo
    let tangemPayAccount: TangemPayAccount
    let tangemPayAccountModel: any TangemPayAccountModel
    let accountTokens: [TangemPayAccountToken]

    var wallets: [TokenSelectorWallet] {
        [
            TokenSelectorWallet(
                wallet: userWalletInfo,
                accounts: .single(makeTangemPayAccountSection())
            ),
        ]
    }
}

// MARK: - The per-token payment account section

private extension TangemPayWithdrawSourceWalletsProvider {
    /// One row per given token, in funding priority order.
    func makeTangemPayAccountSection() -> TokenSelectorAccount {
        let items = accountTokens.fundingPriorityOrdered.map { accountToken in
            TokenSelectorItem(
                userWalletInfo: userWalletInfo,
                kind: .tangemPay(tangemPayAccount, accountToken, tangemPayAccountModel)
            )
        }

        return TokenSelectorAccount(
            account: tangemPayAccountModel,
            itemsProvider: StaticTokenSelectorItemsProvider(items: items),
            rateProvider: nil
        )
    }
}

private struct StaticTokenSelectorItemsProvider: TokenSelectorAccountModelItemsProvider {
    let items: [TokenSelectorItem]

    var itemsPublisher: AnyPublisher<[TokenSelectorItem], Never> {
        Just(items).eraseToAnyPublisher()
    }
}
