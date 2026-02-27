//
//  CommonAccountsAwareTokenSelectorWalletsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemLocalization

final class CommonAccountsAwareTokenSelectorWalletsProvider {
    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository
}

// MARK: - AccountsAwareTokenSelectorWalletsProvider

extension CommonAccountsAwareTokenSelectorWalletsProvider: AccountsAwareTokenSelectorWalletsProvider {
    var wallets: [AccountsAwareTokenSelectorWallet] {
        userWalletRepository.models.map { userWalletModel in
            mapToAccountsAwareTokenSelectorWallet(userWalletModel: userWalletModel)
        }
    }
}

// MARK: - AccountsAwareTokenSelectorWalletsProvider

private extension CommonAccountsAwareTokenSelectorWalletsProvider {
    func mapToAccountsAwareTokenSelectorWallet(userWalletModel: any UserWalletModel) -> AccountsAwareTokenSelectorWallet {
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

        return AccountsAwareTokenSelectorWallet(
            wallet: userWalletInfo,
            accounts: accounts,
            accountsPublisher: accountsPublisher
        )
    }

    func mapToCryptoAccount(userWalletInfo: UserWalletInfo, cryptoAccount: any CryptoAccountModel) -> AccountsAwareTokenSelectorAccount {
        let itemsProvider = CommonAccountsAwareTokenSelectorAccountModelItemsProvider(
            userWalletInfo: userWalletInfo,
            cryptoAccount: cryptoAccount
        )

        return AccountsAwareTokenSelectorAccount(
            accountName: cryptoAccount.name,
            accountIcon: cryptoAccount.icon,
            itemsProvider: itemsProvider
        )
    }

    func mapToTangemPayAccount(userWalletInfo: UserWalletInfo, tangemPayAccount: TangemPayAccount) -> AccountsAwareTokenSelectorAccount {
        let itemsProvider = AccountsAwareTokenSelectorTangemPayItemsProvider(
            userWalletInfo: userWalletInfo,
            tangemPayAccount: tangemPayAccount
        )

        return AccountsAwareTokenSelectorAccount(
            accountName: Localization.tangempayTitle,
            accountIcon: .init(name: .wallet, color: .azure),
            itemsProvider: itemsProvider
        )
    }

    func extractActiveTangemPayAccount(from accountModels: [AccountModel]) -> TangemPayAccount? {
        for model in accountModels {
            if case .tangemPay(let tangemPayAccountModel) = model,
               let account = tangemPayAccountModel.state?.tangemPayAccount {
                return account
            }
        }
        return nil
    }

    func mapToAccountType(
        accountModels: [AccountModel],
        userWalletInfo: UserWalletInfo,
        isUserWalletLocked: Bool
    ) -> AccountsAwareTokenSelectorWallet.AccountType {
        let cryptoResult = accountModels.firstStandard()
        let tangemPayAccount = extractActiveTangemPayAccount(from: accountModels)

        let cryptoAccounts: [AccountsAwareTokenSelectorAccount]
        switch cryptoResult {
        case .standard(.single(let account)):
            cryptoAccounts = [mapToCryptoAccount(userWalletInfo: userWalletInfo, cryptoAccount: account)]
        case .standard(.multiple(let accounts)):
            cryptoAccounts = accounts.map { mapToCryptoAccount(userWalletInfo: userWalletInfo, cryptoAccount: $0) }
        case .none, .tangemPay:
            assert(isUserWalletLocked, "Non-locked wallet should contain at least one crypto account (main)")
            cryptoAccounts = []
        }

        var allAccounts = cryptoAccounts
        if let tangemPayAccount {
            allAccounts.append(mapToTangemPayAccount(userWalletInfo: userWalletInfo, tangemPayAccount: tangemPayAccount))
        }

        if allAccounts.count == 1, let single = allAccounts.first {
            return .single(single)
        }

        return .multiple(allAccounts)
    }
}
