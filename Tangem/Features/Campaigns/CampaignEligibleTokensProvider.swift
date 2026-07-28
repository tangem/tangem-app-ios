//
//  CampaignEligibleTokensProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

struct EligibleTokensWalletsProvider: TokenSelectorWalletsProvider {
    let base: any TokenSelectorWalletsProvider
    let isEligible: (TokenItem) -> Bool

    var wallets: [TokenSelectorWallet] {
        base.wallets.map { wallet in
            TokenSelectorWallet(wallet: wallet.wallet, accounts: filtered(wallet.accounts))
        }
    }

    private func filtered(_ accounts: TokenSelectorWallet.AccountType) -> TokenSelectorWallet.AccountType {
        switch accounts {
        case .single(let account):
            .single(wrapped(account))
        case .multiple(let accounts):
            .multiple(accounts.map(wrapped))
        }
    }

    private func wrapped(_ account: TokenSelectorAccount) -> TokenSelectorAccount {
        TokenSelectorAccount(
            account: account.account,
            itemsProvider: EligibleTokensItemsProvider(base: account.itemsProvider, isEligible: isEligible),
            rateProvider: account.rateProvider
        )
    }
}

struct EligibleTokensItemsProvider: TokenSelectorAccountModelItemsProvider {
    let base: any TokenSelectorAccountModelItemsProvider
    let isEligible: (TokenItem) -> Bool

    var itemsPublisher: AnyPublisher<[TokenSelectorItem], Never> {
        base.itemsPublisher
            .map { items in items.filter { isEligible($0.tokenItem) } }
            .eraseToAnyPublisher()
    }
}

enum EligibleTokenMatcher {
    private struct Key: Hashable {
        let networkId: String
        let contractAddress: String
    }

    static func make(from tokens: [BannerPromotion.Response.Token]) -> (TokenItem) -> Bool {
        let keys = Set(tokens.map { Key(networkId: $0.networkId, contractAddress: $0.tokenAddress.lowercased()) })

        return { tokenItem in
            guard let contractAddress = tokenItem.contractAddress?.lowercased() else {
                return false
            }

            return keys.contains(Key(networkId: tokenItem.networkId, contractAddress: contractAddress))
        }
    }
}
