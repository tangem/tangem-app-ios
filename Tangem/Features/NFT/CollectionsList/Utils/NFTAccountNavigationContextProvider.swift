//
//  NFTAccountNavigationContextProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemNFT
import TangemFoundation

final class NFTAccountNavigationContextProvider {
    private let userWalletModel: UserWalletModel

    /// Cached mapping: account ID -> receive data
    /// Built lazily on first call to getInfoFromAccount
    private var accountIDToDataMap: [AnyHashable: NFTNavigationInput]?
    private var bag = Set<AnyCancellable>()

    init(userWalletModel: UserWalletModel) {
        self.userWalletModel = userWalletModel
        bind()
    }

    private func bind() {
        userWalletModel.accountModelsManager.accountModelsPublisher
            .withWeakCaptureOf(self)
            .sink { provider, _ in
                // Invalidate cache when user wallets change
                provider.accountIDToDataMap = nil
            }
            .store(in: &bag)
    }

    private func buildAccountIDToDataMap() -> [AnyHashable: NFTNavigationInput] {
        var map: [AnyHashable: NFTNavigationInput] = [:]

        for accountModel in userWalletModel.accountModelsManager.accountModels {
            if case .standard(let cryptoAccounts) = accountModel {
                let allAccounts: [any CryptoAccountModel]
                switch cryptoAccounts {
                case .single(let account):
                    allAccounts = [account]
                case .multiple(let accounts):
                    allAccounts = accounts
                }

                for account in allAccounts {
                    let accountID = account.id.toAnyHashable()
                    map[accountID] = NFTNavigationInput(
                        userWalletModel: userWalletModel,
                        name: account.name,
                        walletModelsManager: account.walletModelsManager
                    )
                }
            }
        }

        return map
    }

    private func findAndMakeDataForAccount(id: AnyHashable) -> NFTNavigationInput? {
        if accountIDToDataMap == nil {
            accountIDToDataMap = buildAccountIDToDataMap()
        }

        return accountIDToDataMap?[id]
    }
}

extension NFTAccountNavigationContextProvider: NFTAccountNavigationContextProviding {
    func provide(for accountID: AnyHashable) -> NFTNavigationContext? {
        findAndMakeDataForAccount(id: accountID)
    }
}
