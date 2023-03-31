//
//  UserWalletModelMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk

struct UserWalletModelMock: UserWalletModel {
    var userTokenListManager: UserTokenListManager { UserTokenListManagerMock() }
    var userWallet: UserWallet {
        UserWallet(userWalletId: Data(), name: "", card: .init(card: .card), associatedCardIds: [], walletData: .none, artwork: nil, isHDWalletAllowed: false)
    }

    var totalBalanceProvider: TotalBalanceProviding { TotalBalanceProviderMock() }

    func updateUserWalletModel(with config: UserWalletConfig) {}

    func updateUserWallet(_ userWallet: UserWallet) {}

    func getWalletModels() -> [WalletModel] { [] }

    func subscribeToWalletModels() -> AnyPublisher<[WalletModel], Never> { .just(output: []) }

    func getSavedEntries() -> [StorageEntry] { [] }

    func getEntriesWithoutDerivation() -> [StorageEntry] { [] }

    func subscribeToEntriesWithoutDerivation() -> AnyPublisher<[StorageEntry], Never> { .just(output: []) }

    func canManage(amountType: BlockchainSdk.Amount.AmountType, blockchainNetwork: BlockchainNetwork) -> Bool { false }

    func update(entries: [StorageEntry]) {}

    func append(entries: [StorageEntry]) {}

    func remove(item: CommonUserWalletModel.RemoveItem) {}

    func initialUpdate() {}

    func updateWalletModels() {}

    func updateAndReloadWalletModels(silent: Bool, completion: @escaping () -> Void) {}
}
