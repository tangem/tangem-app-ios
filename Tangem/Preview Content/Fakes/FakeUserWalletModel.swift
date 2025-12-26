//
//  FakeUserWalletModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk
import BlockchainSdk
import TangemAssets
import TangemNFT
import TangemFoundation

class FakeUserWalletModel: UserWalletModel {
    var hasImportedWallets: Bool { false }
    var keysDerivingInteractor: any KeysDeriving { KeysDerivingMock() }

    var keysRepository: KeysRepository {
        CommonKeysRepository(
            userWalletId: userWalletId,
            encryptionKey: .init(userWalletIdSeed: Data()),
            keys: .cardWallet(keys: [])
        )
    }

    private(set) var name: String
    let emailData: [EmailCollectedData] = []
    let backupInput: OnboardingInput? = nil
    let walletModelsManager: WalletModelsManager
    var nftManager: NFTManager { NFTManagerStub() }
    let userTokensManager: UserTokensManager
    let totalBalanceProvider: TotalBalanceProvider
    let walletImageProvider: WalletImageProviding
    let signer: TangemSigner = CardSigner(filter: .cardId(""), sdk: .init(), twinKey: nil)
    let config: UserWalletConfig
    let isUserWalletLocked: Bool
    let userWalletId: UserWalletId
    var cardsCount: Int
    var hasBackupCards: Bool { cardsCount > 1 }
    var emailConfig: EmailConfig? { nil }
    var cardSetLabel: String { config.cardSetLabel }

    var tangemApiAuthData: TangemApiAuthorizationData? {
        .init(cardId: "", cardPublicKey: Data())
    }

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
            derivationManager: nil,
        )
    }

    var accountModelsManager: AccountModelsManager {
        AccountModelsManagerMock()
    }

    var tangemPayManager: TangemPayManager {
        TangemPayManager(
            userWalletId: userWalletId,
            keysRepository: keysRepository,
            tangemPayAuthorizingInteractor: TangemPayAuthorizingMock(),
            signer: signer
        )
    }

    var refcodeProvider: RefcodeProvider? {
        return nil
    }

    var tokensCount: Int? { walletModelsManager.walletModels.filter { !$0.isMainToken }.count }
    var updatePublisher: AnyPublisher<UpdateResult, Never> { _updatePublisher.eraseToAnyPublisher() }

    private let _updatePublisher: PassthroughSubject<UpdateResult, Never> = .init()

    init(
        userWalletName: String,
        isUserWalletLocked: Bool,
        isDelayed: Bool,
        cardsCount: Int,
        userWalletId: UserWalletId,
        walletManagers: [FakeWalletManager],
        config: UserWalletConfig
    ) {
        self.isUserWalletLocked = isUserWalletLocked
        self.cardsCount = cardsCount
        self.userWalletId = userWalletId
        self.config = config
        name = userWalletName

        walletModelsManager = FakeWalletModelsManager(walletManagers: walletManagers, isDelayed: isDelayed)
        let fakeUserTokenListManager = FakeUserTokenListManager(walletManagers: walletManagers, isDelayed: isDelayed)
        userTokensManager = FakeUserTokensManager(
            derivationManager: FakeDerivationManager(pendingDerivationsCount: 5),
            userTokenListManager: fakeUserTokenListManager
        )
        totalBalanceProvider = TotalBalanceProviderMock()
        walletImageProvider = CardImageProvider(
            input: .init(
                cardId: "",
                cardPublicKey: Data(),
                issuerPublicKey: Data(),
                firmwareVersionType: .release
            )
        )
    }

    var totalBalance: TotalBalanceState {
        .loading(cached: .none)
    }

    var totalBalancePublisher: AnyPublisher<TotalBalanceState, Never> {
        .just(output: totalBalance)
    }

    func validate() -> Bool {
        return true
    }

    func update(type: UpdateRequest) {
        switch type {
        case .newName(let name):
            self.name = name
            _updatePublisher.send(.nameDidChange(name: name))
        default:
            break
        }
    }

    func addAssociatedCard(cardId: String) {}
}

extension FakeUserWalletModel: MainHeaderSupplementInfoProvider {
    var walletHeaderImagePublisher: AnyPublisher<ImageType?, Never> {
        .just(output: config.cardHeaderImage)
    }
}

extension FakeUserWalletModel: AnalyticsContextDataProvider {
    func getAnalyticsContextData() -> AnalyticsContextData? {
        return nil
    }
}

extension FakeUserWalletModel {
    static let allFakeWalletModels = [
        wallet3Cards,
        twins,
        xrpNote,
    ]

    static let wallet3Cards = FakeUserWalletModel(
        userWalletName: "William Wallet",
        isUserWalletLocked: false,
        isDelayed: true,
        cardsCount: 3,
        userWalletId: .init(with: Data.randomData(count: 32)),
        walletManagers: [
            .ethWithTokensManager,
            .btcManager,
            .polygonWithTokensManager,
            .xrpManager,
        ],
        config: UserWalletConfigStubs.walletV2Stub
    )

    static let visa = FakeUserWalletModel(
        userWalletName: "Tangem Visa",
        isUserWalletLocked: false,
        isDelayed: false,
        cardsCount: 1,
        userWalletId: .init(with: Data.randomData(count: 32)),
        walletManagers: [
            .visaWalletManager,
        ],
        config: UserWalletConfigStubs.visaStub
    )

    static let walletWithoutDelay = FakeUserWalletModel(
        userWalletName: "Just A Wallet",
        isUserWalletLocked: false,
        isDelayed: false,
        cardsCount: 1,
        userWalletId: .init(with: Data.randomData(count: 32)),
        walletManagers: [
            .ethWithTokensManager,
            .btcManager,
            .polygonWithTokensManager,
            .xrpManager,
            .xlmManager,
        ],
        config: UserWalletConfigStubs.walletV2Stub
    )

    static let twins = FakeUserWalletModel(
        userWalletName: "Tangem Twins",
        isUserWalletLocked: true,
        isDelayed: true,
        cardsCount: 2,
        userWalletId: .init(with: Data.randomData(count: 32)),
        walletManagers: [.btcManager],
        config: UserWalletConfigStubs.twinStub
    )

    static let xrpNote = FakeUserWalletModel(
        userWalletName: "XRP Note",
        isUserWalletLocked: false,
        isDelayed: true,
        cardsCount: 1,
        userWalletId: .init(with: Data.randomData(count: 32)),
        walletManagers: [.xrpManager],
        config: UserWalletConfigStubs.xrpNoteStub
    )

    static let xlmBird = FakeUserWalletModel(
        userWalletName: "XLM Bird",
        isUserWalletLocked: false,
        isDelayed: true,
        cardsCount: 1,
        userWalletId: .init(with: Data.randomData(count: 32)),
        walletManagers: [.xlmManager],
        config: UserWalletConfigStubs.xlmBirdStub
    )
}
