//
//  TokenHeaderProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemAccounts

struct TokenHeaderProvider {
    @Injected(\.userWalletRepository) private var userWalletRepository: any UserWalletRepository
    @Injected(\.cryptoAccountsGlobalStateProvider) private var cryptoAccountsGlobalStateProvider: CryptoAccountsGlobalStateProvider

    private let userWalletName: String
    private let account: (any BaseAccountModel)?

    init(
        userWalletName: String,
        account: (any BaseAccountModel)?
    ) {
        self.userWalletName = userWalletName
        self.account = account
    }

    func makeHeader() -> TokenHeader {
        guard FeatureProvider.isAvailable(.accounts) else {
            return .wallet(name: userWalletName, hasOnlyOneWallet: userWalletRepository.hasOnlyOneWallet)
        }

        let hasMultipleAccounts = cryptoAccountsGlobalStateProvider.globalCryptoAccountsState() == .multiple

        if hasMultipleAccounts, let account {
            let icon = AccountModelUtils.UI.iconViewData(accountModel: account)
            return .account(name: account.name, icon: icon)
        }

        return .wallet(name: userWalletName, hasOnlyOneWallet: userWalletRepository.hasOnlyOneWallet)
    }
}

enum TokenHeader: Hashable {
    case wallet(name: String, hasOnlyOneWallet: Bool)
    case account(name: String, icon: AccountIconView.ViewData)
}
