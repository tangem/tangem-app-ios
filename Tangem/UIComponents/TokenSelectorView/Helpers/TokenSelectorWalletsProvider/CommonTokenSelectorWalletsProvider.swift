//
//  CommonTokenSelectorWalletsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemPay

final class CommonTokenSelectorWalletsProvider {
    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository

    @Injected(\.cryptoAccountsGlobalStateProvider)
    private var cryptoAccountsGlobalStateProvider: CryptoAccountsGlobalStateProvider

    private let aggregator: BaseAccountModelsAggregator

    init(_ aggregator: BaseAccountModelsAggregator) {
        self.aggregator = aggregator
    }
}

// MARK: - TokenSelectorWalletsProvider

extension CommonTokenSelectorWalletsProvider: TokenSelectorWalletsProvider {
    var wallets: [TokenSelectorWallet] {
        userWalletRepository.models
            .filter { !$0.isUserWalletLocked }
            .map { userWalletModel in
                mapToTokenSelectorWallet(userWalletModel: userWalletModel)
            }
    }
}

// MARK: - TokenSelectorWalletsProvider

private extension CommonTokenSelectorWalletsProvider {
    func mapToTokenSelectorWallet(userWalletModel: any UserWalletModel) -> TokenSelectorWallet {
        let userWalletInfo = userWalletModel.userWalletInfo
        let accounts = mapToAccountType(
            accountModels: aggregator.models(from: userWalletModel.accountModelsManager),
            userWalletInfo: userWalletInfo
        )

        return TokenSelectorWallet(wallet: userWalletInfo, accounts: accounts)
    }

    func mapToTokenSelectorAccount(
        userWalletInfo: UserWalletInfo,
        cryptoAccount: any CryptoAccountModel
    ) -> TokenSelectorAccount {
        let itemsProvider = CommonTokenSelectorCryptoAccountModelItemsProvider(
            userWalletInfo: userWalletInfo,
            cryptoAccount: cryptoAccount
        )

        return TokenSelectorAccount(
            account: cryptoAccount,
            itemsProvider: itemsProvider,
            rateProvider: cryptoAccount.rateProvider,
            currencyCode: nil
        )
    }

    func mapToTokenSelectorAccount(
        userWalletInfo: UserWalletInfo,
        tangemPayAccountModel: any TangemPayAccountModel
    ) -> TokenSelectorAccount {
        let itemsProvider = CommonTokenSelectorTangemPayAccountModelItemsProvider(
            userWalletInfo: userWalletInfo,
            tangemPayAccountModel: tangemPayAccountModel
        )

        return TokenSelectorAccount(
            account: tangemPayAccountModel,
            itemsProvider: itemsProvider,
            rateProvider: nil,
            currencyCode: TangemPayUtilities.fiatItem.currencyCode
        )
    }

    func mapToAccountType(
        accountModels: [any BaseAccountModel],
        userWalletInfo: UserWalletInfo
    ) -> TokenSelectorWallet.AccountType {
        let items: [TokenSelectorAccount] = accountModels.compactMap { accountModel -> TokenSelectorAccount? in
            switch accountModel {
            case let cryptoAccountModel as any CryptoAccountModel:
                return mapToTokenSelectorAccount(userWalletInfo: userWalletInfo, cryptoAccount: cryptoAccountModel)

            case let tangemPayAccountModel as any TangemPayAccountModel:
                return mapToTokenSelectorAccount(userWalletInfo: userWalletInfo, tangemPayAccountModel: tangemPayAccountModel)

            default:
                // A kind the selector let through and this one has no row for — the two are named together at the
                // call site, so they part company only by mistake
                assertionFailure("Unexpected account model kind: \(accountModel)")
                return nil
            }
        }

        let hasTangemPayInResults = accountModels.contains { $0 is any TangemPayAccountModel }

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
