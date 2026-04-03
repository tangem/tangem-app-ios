//
//  CommonTokenSelectorWalletsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

final class CommonTokenSelectorWalletsProvider {
    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository

    @Injected(\.cryptoAccountsGlobalStateProvider)
    private var cryptoAccountsGlobalStateProvider: CryptoAccountsGlobalStateProvider

    @Injected(\.tangemPayAccountGlobalStateProvider)
    private var tangemPayAccountGlobalStateProvider: TangemPayAccountGlobalStateProvider

    private let accountModelFilter: ((AccountModel) -> Bool)?

    init(accountModelFilter: ((AccountModel) -> Bool)? = nil) {
        self.accountModelFilter = accountModelFilter
    }
}

// MARK: - TokenSelectorWalletsProvider

extension CommonTokenSelectorWalletsProvider: TokenSelectorWalletsProvider {
    var wallets: [TokenSelectorWallet] {
        userWalletRepository.models.map { userWalletModel in
            mapToTokenSelectorWallet(userWalletModel: userWalletModel)
        }
    }
}

// MARK: - TokenSelectorWalletsProvider

private extension CommonTokenSelectorWalletsProvider {
    func mapToTokenSelectorWallet(userWalletModel: any UserWalletModel) -> TokenSelectorWallet {
        let userWalletInfo = userWalletModel.userWalletInfo
        let isUserWalletLocked = userWalletModel.isUserWalletLocked
        let accounts = mapToAccountType(
            accountModels: userWalletModel.accountModelsManager.accountModels,
            userWalletInfo: userWalletInfo,
            isUserWalletLocked: isUserWalletLocked
        )
        let accountsPublisher = userWalletModel
            .accountModelsManager
            .accountModelsPublisher
            .withWeakCaptureOf(self)
            .map { mapper, accountModels in
                mapper.mapToAccountType(
                    accountModels: accountModels,
                    userWalletInfo: userWalletInfo,
                    isUserWalletLocked: isUserWalletLocked
                )
            }
            .eraseToAnyPublisher()

        return TokenSelectorWallet(
            wallet: userWalletInfo,
            accounts: accounts,
            accountsPublisher: accountsPublisher
        )
    }

    func mapToTokenSelectorAccount(
        userWalletInfo: UserWalletInfo,
        cryptoAccount: any CryptoAccountModel
    ) -> TokenSelectorAccount {
        let itemsProvider = CommonTokenSelectorCryptoAccountModelItemsProvider(
            userWalletInfo: userWalletInfo,
            cryptoAccount: cryptoAccount
        )

        return TokenSelectorAccount(account: cryptoAccount, itemsProvider: itemsProvider)
    }

    func mapToTokenSelectorAccount(
        userWalletInfo: UserWalletInfo,
        tangemPayAccountModel: any TangemPayAccountModel
    ) -> TokenSelectorAccount {
        let itemsProvider = CommonTokenSelectorTangemPayAccountModelItemsProvider(
            userWalletInfo: userWalletInfo,
            tangemPayAccountModel: tangemPayAccountModel
        )

        return TokenSelectorAccount(account: tangemPayAccountModel, itemsProvider: itemsProvider)
    }

    func mapToAccountType(
        accountModels: [AccountModel],
        userWalletInfo: UserWalletInfo,
        isUserWalletLocked: Bool
    ) -> TokenSelectorWallet.AccountType {
        let filteredAccountModels = accountModelFilter.map { filter in accountModels.filter(filter) } ?? accountModels

        let items: [TokenSelectorAccount] = filteredAccountModels.flatMap { accountModel -> [TokenSelectorAccount] in
            switch accountModel {
            case .standard(.single(let account)):
                [mapToTokenSelectorAccount(userWalletInfo: userWalletInfo, cryptoAccount: account)]

            case .standard(.multiple(let accounts)):
                accounts.map { mapToTokenSelectorAccount(userWalletInfo: userWalletInfo, cryptoAccount: $0) }

            case .tangemPay(let tangemPayAccountModel):
                [
                    mapToTokenSelectorAccount(
                        userWalletInfo: userWalletInfo,
                        tangemPayAccountModel: tangemPayAccountModel
                    ),
                ]
            }
        }

        let hasTangemPayInResults = filteredAccountModels.contains { if case .tangemPay = $0 { return true } else { return false } }

        switch cryptoAccountsGlobalStateProvider.globalCryptoAccountsState() {
        case .single where hasTangemPayInResults:
            return .multiple(items)
        case .single:
            if let item = items.singleElement {
                return .single(item)
            }

            AppLogger.error(error: "Wrong `globalCryptoAccountsState == .single`. But `accountModelsManager.accountModels` has multiple accounts")
            return .multiple(items)
        case .multiple:
            return .multiple(items)
        }
    }
}
