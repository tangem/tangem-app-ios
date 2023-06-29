//
//  LockedUserWallet.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

class LockedUserWallet: UserWalletModel {
    private(set) var userWallet: UserWallet

    private let config: UserWalletConfig

    init(with userWallet: UserWallet) {
        self.userWallet = userWallet
        config = UserWalletConfigFactory(userWallet.cardInfo()).makeConfig()
    }

    var isMultiWallet: Bool { config.hasFeature(.multiCurrency) }

    var userWalletId: UserWalletId { .init(value: userWallet.userWalletId) }

    var userTokenListManager: UserTokenListManager { DummyUserTokenListManager() }

    var totalBalanceProvider: TotalBalanceProviding { DummyTotalBalanceProvider() }

    func initialUpdate() {}

    func updateWalletName(_ name: String) {
        userWallet.name = name
    }
}

extension LockedUserWallet {
    struct DummyUserTokenListManager: UserTokenListManager {
        var userTokens: [StorageEntry] { [] }
        var userTokensPublisher: AnyPublisher<[StorageEntry], Never> { .just(output: []) }

        func contains(_ entry: StorageEntry) -> Bool { return false }
        func update(_ type: CommonUserTokenListManager.UpdateType) {}
        func updateLocalRepositoryFromServer(result: @escaping (Result<Void, Error>) -> Void) {}
    }

    struct DummyTotalBalanceProvider: TotalBalanceProviding {
        func totalBalancePublisher() -> AnyPublisher<LoadingValue<TotalBalanceProvider.TotalBalance>, Never> {
            Empty().eraseToAnyPublisher()
        }
    }
}
