//
//  UserWalletModelMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class UserWalletModelMock: UserWalletModel {
    var isMultiWallet: Bool { true }
    var tokensCount: Int? { 7 }
    var config: UserWalletConfig { fatalError("UserWalletConfigMock doesn't exist") }
    var userWalletId: UserWalletId { .init(value: Data()) }
    var userWallet: UserWallet { fatalError("UserWalletMock doesn't exist") }

    var walletModelsManager: WalletModelsManager { WalletModelsManagerMock() }

    var userTokensManager: UserTokensManager { UserTokensManagerMock() }

    var userTokenListManager: UserTokenListManager { UserTokenListManagerMock() }

    var signer: TangemSigner { fatalError("TangemSignerMock doesn't exist") }

    var updatePublisher: AnyPublisher<Void, Never> { Empty().eraseToAnyPublisher() }

    var emailData: [EmailCollectedData] { [] }

    var backupInput: OnboardingInput? { nil }

    var twinInput: OnboardingInput? { nil }

    var cardImagePublisher: AnyPublisher<CardImageResult, Never> { Empty().eraseToAnyPublisher() }

    func updateWalletName(_ name: String) {}

    var cardHeaderImagePublisher: AnyPublisher<ImageType?, Never> { Empty().eraseToAnyPublisher() }

    var userWalletNamePublisher: AnyPublisher<String, Never> { Empty().eraseToAnyPublisher() }

    var totalBalancePublisher: AnyPublisher<LoadingValue<TotalBalance>, Never> { Empty().eraseToAnyPublisher() }

    var cardsCount: Int { 3 }

    func getAnalyticsContextData() -> AnalyticsContextData? { nil }

    var isUserWalletLocked: Bool { false }

    var isTokensListEmpty: Bool { false }
}
