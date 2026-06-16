//
//  AddTokenEligibleAccountsResolver.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemAccounts

enum AddTokenEligibleAccountsResolver {
    typealias EligibleAccount = (userWallet: any UserWalletModel, cryptoAccount: any CryptoAccountModel)

    /// Returns unlocked multi-currency wallets paired with their primary crypto account.
    /// Callers needing the single-wallet/single-account fast path should query
    /// `OneAndOnlyAccountFinder.find` separately.
    static func resolveAll(in userWalletModels: [any UserWalletModel]) -> [EligibleAccount] {
        userWalletModels
            .filter { !$0.isUserWalletLocked && $0.config.hasFeature(.multiCurrency) }
            .compactMap { userWallet -> EligibleAccount? in
                guard
                    let accountModel = userWallet.accountModelsManager.accountModels.firstStandard(),
                    let cryptoAccount = pickPrimaryAccount(from: accountModel)
                else { return nil }
                return (userWallet, cryptoAccount)
            }
    }

    private static func pickPrimaryAccount(from accountModel: AccountModel) -> (any CryptoAccountModel)? {
        switch accountModel {
        case .standard(.single(let model)):
            return model
        case .standard(.multiple(let models)):
            return models.first(where: { $0.isMainAccount }) ?? models.first
        case .tangemPay:
            return nil
        }
    }
}
