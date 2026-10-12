//
//  WalletModelOwnerResolver.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation

struct WalletModelOwnerResolver {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    /// `WalletModel.account` is a weak reference, so an instance that outlived its account is matched by id
    /// against the wallet's current accounts, and the account's own instance is returned in its place.
    func resolve(_ walletModel: any WalletModel) -> WalletModelOwner? {
        guard let userWalletModel = userWalletRepository.models[walletModel.userWalletId] else {
            return nil
        }

        if let account = walletModel.account {
            return WalletModelOwner(userWalletModel: userWalletModel, account: account, walletModel: walletModel)
        }

        for account in AccountModelsAggregator(.crypto, .joint).models(from: userWalletModel.accountModelsManager) {
            if let current = account.walletModelsManager.walletModels.first(where: { $0.id == walletModel.id }) {
                return WalletModelOwner(userWalletModel: userWalletModel, account: account, walletModel: current)
            }
        }

        return nil
    }
}

struct WalletModelOwner {
    let userWalletModel: any UserWalletModel
    let account: any CryptoAccountModel
    let walletModel: any WalletModel
}
