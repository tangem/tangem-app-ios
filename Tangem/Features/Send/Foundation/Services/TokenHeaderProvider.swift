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
    @Injected(\.tangemPayAccountGlobalStateProvider) private var tangemPayAccountGlobalStateProvider: TangemPayAccountGlobalStateProvider

    private let userWalletName: String
    private let account: (any BaseAccountModel)?

    init(
        userWalletName: String,
        account: (any BaseAccountModel)?
    ) {
        self.userWalletName = userWalletName
        self.account = account
    }

    func makeHeader() -> TokenHeader? {
        let hasMultipleCryptoAccounts = cryptoAccountsGlobalStateProvider.globalCryptoAccountsState() == .multiple
        let hasMultipleAccounts = hasMultipleCryptoAccounts || tangemPayAccountGlobalStateProvider.hasTangemPayAccount

        guard hasMultipleAccounts else {
            return nil
        }

        guard let account else {
            assertionFailure("Account should always be available in accounts-aware context")
            return nil
        }

        let icon = AccountModelUtils.UI.iconViewData(accountModel: account)
        return .account(name: account.name, icon: icon)
    }
}

enum TokenHeader: Hashable {
    case account(name: String, icon: AccountIconView.ViewData)
}
