//
//  ExpressInteractorTokenHeaderProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemLocalization

struct ExpressInteractorTokenHeaderProvider {
    @Injected(\.userWalletRepository) private var userWalletRepository: any UserWalletRepository
    @Injected(\.cryptoAccountsGlobalStateProvider) private var cryptoAccountsGlobalStateProvider: CryptoAccountsGlobalStateProvider

    private let userWalletInfo: UserWalletInfo
    private let account: (any BaseAccountModel)?

    init(
        userWalletInfo: UserWalletInfo,
        account: (any BaseAccountModel)?
    ) {
        self.userWalletInfo = userWalletInfo
        self.account = account
    }

    func makeHeader() -> ExpressInteractorTokenHeader? {
        guard FeatureProvider.isAvailable(.accounts) else {
            // Save legacy behaviour
            return .none
        }

        let hasMultipleAccounts = cryptoAccountsGlobalStateProvider.globalCryptoAccountsState() == .multiple

        if hasMultipleAccounts, let account {
            let icon = AccountModelUtils.UI.iconViewData(accountModel: account)
            return .account(name: account.name, icon: icon)
        }

        if !userWalletRepository.hasOnlyOneWallet {
            return .wallet(name: userWalletInfo.name)
        }

        return .none
    }
}
