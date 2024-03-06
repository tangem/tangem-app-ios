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

class FakeUserWalletModel: UserWalletModel, ObservableObject {
    let emailData: [EmailCollectedData] = []
    let backupInput: OnboardingInput? = nil
    let twinInput: OnboardingInput? = nil
    let walletModelsManager: WalletModelsManager
    let userTokenListManager: UserTokenListManager
    let userTokensManager: UserTokensManager
    let totalBalanceProvider: TotalBalanceProviding
    let signer: TangemSigner = .init(filter: .cardId(""), sdk: .init(), twinKey: nil)
    let config: UserWalletConfig
    let userWallet: StoredUserWallet
    let isUserWalletLocked: Bool
    let userWalletId: UserWalletId
    var hasBackupCards: Bool { cardsCount > 1 }
    var emailConfig: EmailConfig? { nil }
    var cardsCount: Int

    var tangemApiAuthData: TangemApiTarget.AuthData {
        .init(cardId: "", cardPublicKey: Data())
    }

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

    var userWalletName: String { _userWalletNamePublisher.value }

    var tokensCount: Int? { walletModelsManager.walletModels.filter { !$0.isMainToken }.count }
    var updatePublisher: AnyPublisher<Void, Never> { _updatePublisher.eraseToAnyPublisher() }
    var cardImagePublisher: AnyPublisher<CardImageResult, Never>

    private let _updatePublisher: PassthroughSubject<Void, Never> = .init()
    private let _userWalletNamePublisher: CurrentValueSubject<String, Never>

    init(
        userWalletName: String,
        isUserWalletLocked: Bool,
        isDelayed: Bool,
        cardsCount: Int,
        userWalletId: UserWalletId,
        walletManagers: [FakeWalletManager],
        userWallet: StoredUserWallet
    ) {
        self.isUserWalletLocked = isUserWalletLocked
        self.cardsCount = cardsCount
        self.userWalletId = userWalletId
        config = UserWalletConfigFactory(userWallet.cardInfo()).makeConfig()
        _userWalletNamePublisher = .init(userWalletName)

        walletModelsManager = FakeWalletModelsManager(walletManagers: walletManagers, isDelayed: isDelayed)
        let fakeUserTokenListManager = FakeUserTokenListManager(walletManagers: walletManagers, isDelayed: isDelayed)
        userTokenListManager = fakeUserTokenListManager
        userTokensManager = FakeUserTokensManager(
            derivationManager: FakeDerivationManager(pendingDerivationsCount: 5),
            userTokenListManager: fakeUserTokenListManager
        )
        totalBalanceProvider = TotalBalanceProviderMock()

        self.userWallet = userWallet
        cardImagePublisher = Just(.cached(Assets.Cards.walletSingle.uiImage)).eraseToAnyPublisher()
    }

    func updateWalletName(_ name: String) {
        _userWalletNamePublisher.send(name)
        _updatePublisher.send(())
    }

    var totalBalancePublisher: AnyPublisher<LoadingValue<TotalBalance>, Never> {
        .just(output: .loading)
    }

    func validate() -> Bool {
        return true
    }

    func onBackupCreated(_ card: Card) {}
}

extension FakeUserWalletModel: MainHeaderSupplementInfoProvider {
    var userWalletNamePublisher: AnyPublisher<String, Never> { _userWalletNamePublisher.eraseToAnyPublisher() }

    var cardHeaderImagePublisher: AnyPublisher<ImageType?, Never> {
        .just(output: config.cardHeaderImage)
    }

    var isTokensListEmpty: Bool { walletModelsManager.walletModels.isEmpty }
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
        userWallet: UserWalletStubs.walletV2Stub
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
        userWallet: UserWalletStubs.visaStub
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
        userWallet: UserWalletStubs.walletV2Stub
    )

    static let twins = FakeUserWalletModel(
        userWalletName: "Tangem Twins",
        isUserWalletLocked: true,
        isDelayed: true,
        cardsCount: 2,
        userWalletId: .init(with: Data.randomData(count: 32)),
        walletManagers: [.btcManager],
        userWallet: UserWalletStubs.twinStub
    )

    static let xrpNote = FakeUserWalletModel(
        userWalletName: "XRP Note",
        isUserWalletLocked: false,
        isDelayed: true,
        cardsCount: 1,
        userWalletId: .init(with: Data.randomData(count: 32)),
        walletManagers: [.xrpManager],
        userWallet: UserWalletStubs.xrpNoteStub
    )

    static let xlmBird = FakeUserWalletModel(
        userWalletName: "XLM Bird",
        isUserWalletLocked: false,
        isDelayed: true,
        cardsCount: 1,
        userWalletId: .init(with: Data.randomData(count: 32)),
        walletManagers: [.xlmManager],
        userWallet: UserWalletStubs.xlmBirdStub
    )
}
