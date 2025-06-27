//
//  UserWalletModelMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemAssets
import TangemSdk
import TangemNFT
import BlockchainSdk

class UserWalletModelMock: UserWalletModel {
    var hasImportedWallets: Bool { false }
    var keysDerivingInteractor: any KeysDeriving { KeysDerivingMock() }
    var keysRepository: KeysRepository { CommonKeysRepository(with: []) }
    var name: String { "" }
    var hasBackupCards: Bool { false }
    var emailConfig: EmailConfig? { nil }
    var tokensCount: Int? { 7 }
    var config: UserWalletConfig { fatalError("UserWalletConfigMock doesn't exist") }
    var userWalletId: UserWalletId { .init(value: Data()) }

    var totalBalance: TotalBalanceState { .empty }

    var walletModelsManager: WalletModelsManager { WalletModelsManagerMock() }

    var userTokensManager: UserTokensManager { UserTokensManagerMock() }

    var userTokenListManager: UserTokenListManager { UserTokenListManagerMock() }

    var walletImageProvider: WalletImageProviding {
        CardImageProviderMock()
    }

    var nftManager: NFTManager { NFTManagerStub() }

    var signer: TangemSigner { fatalError("TangemSignerMock doesn't exist") }

    var updatePublisher: AnyPublisher<Void, Never> { Empty().eraseToAnyPublisher() }

    var emailData: [EmailCollectedData] { [] }

    var tangemApiAuthData: TangemApiTarget.AuthData {
        .init(cardId: "", cardPublicKey: Data())
    }

    var backupInput: OnboardingInput? { nil }

    var walletHeaderImagePublisher: AnyPublisher<ImageType?, Never> { Empty().eraseToAnyPublisher() }

    var userWalletNamePublisher: AnyPublisher<String, Never> { Empty().eraseToAnyPublisher() }

    var totalBalancePublisher: AnyPublisher<TotalBalanceState, Never> { Empty().eraseToAnyPublisher() }

    var cardsCount: Int { 3 }

    var isUserWalletLocked: Bool { false }

    var isTokensListEmpty: Bool { false }

    var analyticsContextData: AnalyticsContextData {
        .init(
            productType: .other,
            batchId: "",
            firmware: "",
            baseCurrency: "",
            userWalletId: userWalletId
        )
    }

    var wcWalletModelProvider: WalletConnectWalletModelProvider {
        CommonWalletConnectWalletModelProvider(walletModelsManager: walletModelsManager)
    }

    var userTokensPushNotificationsManager: UserTokensPushNotificationsManager {
        CommonUserTokensPushNotificationsManager(
            userWalletId: userWalletId,
            walletModelsManager: walletModelsManager,
            derivationManager: nil,
            userTokenListManager: userTokenListManager
        )
    }

    var refcodeProvider: RefcodeProvider? {
        return nil
    }

    var totalSignedHashes: Int { 0 }

    func updateWalletName(_ name: String) {}

    func updateWalletPushNotifyStatus(_ status: UserWalletPushNotifyStatus) {}

    func getAnalyticsContextData() -> AnalyticsContextData? { nil }

    func validate() -> Bool { true }

    func onBackupUpdate(type: BackupUpdateType) {}

    func addAssociatedCard(_ cardId: String) {}
}
