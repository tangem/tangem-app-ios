//
//  UserWalletModelMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk

class UserWalletModelMock: UserWalletModel {
    var cardHeaderImage: ImageType?

    var isUserWalletLocked: Bool { false }

    var signer: TangemSigner = .init(with: nil, sdk: .init())

    var walletModelsManager: WalletModelsManager { WalletModelsManagerMock() }
    var userTokenListManager: UserTokenListManager { UserTokenListManagerMock() }
    var userTokensManager: UserTokensManager { UserTokensManagerMock() }

    var isMultiWallet: Bool { false }

    var didPerformInitialTokenSync: Bool { true }

    var tokensCount: Int? { 10 }

    var cardsCount: Int { 1 }

    var userWalletId: UserWalletId { .init(with: Data()) }

    var emailConfig: EmailConfig? { nil }

    var userWallet: UserWallet {
        UserWallet(userWalletId: Data(), name: "", card: .init(card: .walletWithBackup), associatedCardIds: [], walletData: .none, artwork: nil, isHDWalletAllowed: false)
    }

    var updatePublisher: AnyPublisher<Void, Never> { .just }
    var didPerformInitialTokenSyncPublisher: AnyPublisher<Bool, Never> { .just(output: true) }

    var userWalletNamePublisher: AnyPublisher<String, Never> { .just(output: "") }

    func initialUpdate() {}
    func updateWalletName(_ name: String) {}

    func totalBalancePublisher() -> AnyPublisher<LoadingValue<TotalBalanceProvider.TotalBalance>, Never> {
        .just(output: .loading)
    }
}
