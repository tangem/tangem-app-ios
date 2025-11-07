//
//  AccountsAwareUserTokenListExternalParametersProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt

// [REDACTED_TODO_COMMENT]
final class AccountsAwareUserTokenListExternalParametersProvider {
    private var subscriptions: AnyCancellable?
    private var boxedWalletModels: [WeakBox] = []
    private let userTokensPushNotificationsManager: UserTokensPushNotificationsManager

    init(
        accountModelsManager: AccountModelsManager,
        userTokensPushNotificationsManager: UserTokensPushNotificationsManager
    ) {
        self.userTokensPushNotificationsManager = userTokensPushNotificationsManager
        subscriptions = bind(to: accountModelsManager)
    }

    private func bind(to accountModelsManager: AccountModelsManager) -> AnyCancellable {
        return accountModelsManager
            .accountModelsPublisher
            .map { accountModels -> [any CryptoAccountModel] in
                return accountModels
                    .reduce(into: []) { partialResult, accountModel in
                        switch accountModel {
                        case .standard(.single(let cryptoAccountModel)):
                            partialResult.append(cryptoAccountModel)
                        case .standard(.multiple(let cryptoAccountModels)):
                            partialResult += cryptoAccountModels
                        }
                    }
            }
            .flatMap { cryptoAccountModels in
                return cryptoAccountModels
                    .map(\.walletModelsManager.walletModelsPublisher)
                    .combineLatest()
            }
            .map { walletModelsArrays in
                return walletModelsArrays
                    .flatMap(\.self)
                    .map(WeakBox.init(object:))
            }
            .assign(to: \.boxedWalletModels, on: self, ownership: .weak)
    }
}

// MARK: - UserTokenListExternalParametersProvider protocol conformance

extension AccountsAwareUserTokenListExternalParametersProvider: UserTokenListExternalParametersProvider {
    func provideTokenListAddresses() -> [WalletModelId: [String]]? {
        let walletModels = boxedWalletModels.compactMap(\.object)
        let tokenListNotifyStatusValue = provideTokenListNotifyStatusValue()

        return UserTokenListExternalParametersHelper.provideTokenListAddresses(
            with: walletModels,
            tokenListNotifyStatusValue: tokenListNotifyStatusValue
        )
    }

    func provideTokenListNotifyStatusValue() -> Bool {
        UserTokenListExternalParametersHelper.provideTokenListNotifyStatusValue(with: userTokensPushNotificationsManager)
    }
}

// MARK: - Auxiliary types

private extension AccountsAwareUserTokenListExternalParametersProvider {
    struct WeakBox {
        weak var object: (any WalletModel)?
    }
}
