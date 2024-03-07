//
//  UserWalletModelMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk

class UserWalletModelMock: UserWalletModel {
    var hasBackupCards: Bool { false }
    var emailConfig: EmailConfig? { nil }
    var tokensCount: Int? { 7 }
    var config: UserWalletConfig { fatalError("UserWalletConfigMock doesn't exist") }
    var userWalletId: UserWalletId { .init(value: Data()) }
    var userWallet: StoredUserWallet { fatalError("UserWalletMock doesn't exist") }

    var walletModelsManager: WalletModelsManager { WalletModelsManagerMock() }

    var userTokensManager: UserTokensManager { UserTokensManagerMock() }

    var userTokenListManager: UserTokenListManager { UserTokenListManagerMock() }

    var signer: TangemSigner { fatalError("TangemSignerMock doesn't exist") }

    var updatePublisher: AnyPublisher<Void, Never> { Empty().eraseToAnyPublisher() }

    var emailData: [EmailCollectedData] { [] }

    var tangemApiAuthData: TangemApiTarget.AuthData {
        .init(cardId: "", cardPublicKey: Data())
    }

    var backupInput: OnboardingInput? { nil }

    var twinInput: OnboardingInput? { nil }

    var cardImagePublisher: AnyPublisher<CardImageResult, Never> { Empty().eraseToAnyPublisher() }

    var cardHeaderImagePublisher: AnyPublisher<ImageType?, Never> { Empty().eraseToAnyPublisher() }

    var userWalletNamePublisher: AnyPublisher<String, Never> { Empty().eraseToAnyPublisher() }

    var totalBalancePublisher: AnyPublisher<LoadingValue<TotalBalance>, Never> { Empty().eraseToAnyPublisher() }

    var cardsCount: Int { 3 }

    var isUserWalletLocked: Bool { false }

    var isTokensListEmpty: Bool { false }

    var analyticsContextData: AnalyticsContextData {
        .init(
            id: "",
            productType: .other,
            batchId: "",
            firmware: "",
            baseCurrency: ""
        )
    }

    var wcWalletModelProvider: WalletConnectWalletModelProvider {
        CommonWalletConnectWalletModelProvider(walletModelsManager: walletModelsManager)
    }

    func updateWalletName(_ name: String) {}

    func getAnalyticsContextData() -> AnalyticsContextData? { nil }

    func validate() -> Bool { true }

    func onBackupCreated(_ card: Card) {}
}
