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
import TangemNFT
import BlockchainSdk
import TangemFoundation

class UserWalletModelMock: UserWalletModel {
    var hasImportedWallets: Bool { false }
    var keysDerivingInteractor: any KeysDeriving { KeysDerivingMock() }

    var keysRepository: KeysRepository {
        CommonKeysRepository(
            userWalletId: userWalletId,
            encryptionKey: .init(userWalletIdSeed: Data()),
            keys: .cardWallet(keys: [])
        )
    }

    var name: String { "" }
    var hasBackupCards: Bool { false }
    var emailConfig: EmailConfig? { nil }
    var tokensCount: Int? { 7 }
    var config: UserWalletConfig { fatalError("UserWalletConfigMock doesn't exist") }
    var userWalletId: UserWalletId { .init(value: Data()) }

    var totalBalance: TotalBalanceState { .empty }

    var walletModelsManager: WalletModelsManager { WalletModelsManagerMock() }

    var userTokensManager: UserTokensManager { UserTokensManagerMock() }

    var walletImageProvider: WalletImageProviding {
        CardImageProviderMock()
    }

    var nftManager: NFTManager { NFTManagerStub() }

    var signer: TangemSigner { fatalError("TangemSignerMock doesn't exist") }

    private let _updatePublisher: PassthroughSubject<UpdateResult, Never> = .init()

    var updatePublisher: AnyPublisher<UpdateResult, Never> { _updatePublisher.eraseToAnyPublisher() }

    var emailData: [EmailCollectedData] { [] }

    var tangemApiAuthData: TangemApiAuthorizationData? {
        .init(cardId: "", cardPublicKey: Data())
    }

    var backupInput: OnboardingInput? { nil }

    var walletHeaderImagePublisher: AnyPublisher<ImageType?, Never> { Empty().eraseToAnyPublisher() }

    var totalBalancePublisher: AnyPublisher<TotalBalanceState, Never> { Empty().eraseToAnyPublisher() }

    var cardSetLabel: String { config.cardSetLabel }

    var isUserWalletLocked: Bool { false }

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

    var wcAccountsWalletModelProvider: WalletConnectAccountsWalletModelProvider {
        CommonWalletConnectAccountsWalletModelProvider(accountModelsManager: accountModelsManager)
    }

    var userTokensPushNotificationsManager: UserTokensPushNotificationsManager {
        CommonUserTokensPushNotificationsManager(
            userWalletId: userWalletId,
            walletModelsManager: walletModelsManager,
            userTokensManager: userTokensManager,
            remoteStatusSyncing: UserTokensPushNotificationsRemoteStatusSyncingStub(),
            derivationManager: nil
        )
    }

    var accountModelsManager: AccountModelsManager {
        AccountModelsManagerMock()
    }

    var tangemPayManager: TangemPayManager {
        TangemPayBuilder(
            userWalletId: userWalletId,
            keysRepository: keysRepository,
            authorizingInteractor: TangemPayAuthorizingMock(),
            signer: signer
        )
        .buildTangemPayManager()
    }

    var refcodeProvider: RefcodeProvider? {
        return nil
    }

    func updateWalletPushNotifyStatus(_ status: UserWalletPushNotifyStatus) {}

    func getAnalyticsContextData() -> AnalyticsContextData? { nil }

    func validate() -> Bool { true }

    func update(type: UpdateRequest) {}

    func addAssociatedCard(cardId: String) {}
}
