//
//  CommonUserWalletModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import BlockchainSdk
import TangemAssets
import TangemSdk
import TangemNFT

class HotUserWalletModel {
    // MARK: Services

    @Injected(\.tangemApiService) var tangemApiService: TangemApiService
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.pushNotificationsInteractor) private var pushNotificationsInteractor: PushNotificationsInteractor

    let walletModelsManager: WalletModelsManager
    let userTokensManager: UserTokensManager
    let userTokenListManager: UserTokenListManager
    let nftManager: NFTManager
    let keysRepository: KeysRepository
    let derivationManager: DerivationManager?
    let totalBalanceProvider: TotalBalanceProviding
    let walletImageProvider: WalletImageProviding
    let userTokensPushNotificationsManager: UserTokensPushNotificationsManager

    private let walletManagersRepository: WalletManagersRepository

    var emailConfig: EmailConfig? {
        hotUserWalletConfig.emailConfig
    }

    let userWalletId: UserWalletId

    private(set) var hotWalletInfo: HotWalletInfo
    private var hotUserWalletConfig: HotUserWalletConfig

    private(set) var name: String

    private let _updatePublisher: PassthroughSubject<Void, Never> = .init()
    private let _userWalletNamePublisher: CurrentValueSubject<String, Never>
    private let _walletHeaderImagePublisher: CurrentValueSubject<ImageType?, Never>
    private var signSubscription: AnyCancellable?
    private var _signer: TransactionSigner {
        didSet {
            bindSigner()
        }
    }

    init(
        hotWalletInfo: HotWalletInfo,
        name: String,
        config: HotUserWalletConfig,
        userWalletId: UserWalletId,
        associatedCardIds: Set<String>,
        walletManagersRepository: WalletManagersRepository,
        walletModelsManager: WalletModelsManager,
        userTokensManager: UserTokensManager,
        userTokenListManager: UserTokenListManager,
        nftManager: NFTManager,
        keysRepository: KeysRepository,
        derivationManager: DerivationManager?,
        totalBalanceProvider: TotalBalanceProviding,
        userTokensPushNotificationsManager: UserTokensPushNotificationsManager
    ) {
        self.hotWalletInfo = hotWalletInfo
        hotUserWalletConfig = config
        self.userWalletId = userWalletId
        self.name = name

        self.walletManagersRepository = walletManagersRepository
        self.walletModelsManager = walletModelsManager
        self.userTokensManager = userTokensManager
        self.userTokenListManager = userTokenListManager
        self.nftManager = nftManager
        self.keysRepository = keysRepository
        self.derivationManager = derivationManager
        self.totalBalanceProvider = totalBalanceProvider
        self.userTokensPushNotificationsManager = userTokensPushNotificationsManager
        walletImageProvider = HotWalletImageProvider()

        _signer = config.transactionSigner
        _userWalletNamePublisher = .init(name)
        _walletHeaderImagePublisher = .init(config.cardHeaderImage)
        appendPersistentBlockchains()
        bind()

        userTokensManager.sync {}
    }

    deinit {
        AppLogger.debug(self)
    }

    private func appendPersistentBlockchains() {
        guard let persistentBlockchains = config.persistentBlockchains else {
            return
        }

        userTokenListManager.update(.append(persistentBlockchains), shouldUpload: true)
    }

    private func onUpdate() {
        AppLogger.info("Updating with new card")
        hotUserWalletConfig = UserWalletConfigFactory().makeConfig(hotWalletInfo: hotWalletInfo)
        _walletHeaderImagePublisher.send(config.cardHeaderImage)
        _signer = config.transactionSigner
        // prevent save until onboarding completed
        if userWalletRepository.models.first(where: { $0.userWalletId == userWalletId }) != nil {
            userWalletRepository.save()
        }
        _updatePublisher.send()
    }

    private func bind() {
        bindSigner()
    }

    private func bindSigner() {}
}

// MARK: - UserWalletModel

extension HotUserWalletModel: UserWalletModel {
    var hasBackupCards: Bool { false }

    var config: UserWalletConfig { hotUserWalletConfig as UserWalletConfig }

    var tangemApiAuthData: TangemApiTarget.AuthData { fatalError("Unimplemented") }

    var imageProvider: WalletImageProviding { walletImageProvider }

//    func validate() -> Bool
//    func onBackupUpdate(type: BackupUpdateType)
//    func updateWalletName(_ name: String)
//    func addAssociatedCard(_ cardId: String)

    var totalSignedHashes: Int {
        0
    }

    var wcWalletModelProvider: WalletConnectWalletModelProvider {
        CommonWalletConnectWalletModelProvider(walletModelsManager: walletModelsManager)
    }

    var refcodeProvider: RefcodeProvider? {
        nil
    }

    var cardsCount: Int {
        config.cardsCount
    }

    var signer: TransactionSigner { _signer }

    var emailData: [EmailCollectedData] {
        var data = config.emailData

        let userWalletIdItem = EmailCollectedData(type: .card(.userWalletId), data: userWalletId.stringValue)
        data.append(userWalletIdItem)

        return data
    }

    var updatePublisher: AnyPublisher<Void, Never> {
        _updatePublisher.eraseToAnyPublisher()
    }

    func updateWalletName(_ name: String) {
        self.name = name
        _userWalletNamePublisher.send(name)
        userWalletRepository.save()
    }

    var backupInput: OnboardingInput? { nil }

    func onBackupUpdate(type: BackupUpdateType) {
        fatalError("This method is should not be called in HotUserWalletModel")
    }

    func addAssociatedCard(_ cardId: String) {
        fatalError("This method is should not be called in HotUserWalletModel")
    }

    func validate() -> Bool {
        fatalError("This method is should not be called in HotUserWalletModel")
    }
}

extension HotUserWalletModel: MainHeaderSupplementInfoProvider {
    var userWalletHeaderImagePublisher: AnyPublisher<ImageType?, Never> { _walletHeaderImagePublisher.removeDuplicates().eraseToAnyPublisher() }

    var userWalletNamePublisher: AnyPublisher<String, Never> { _userWalletNamePublisher.eraseToAnyPublisher() }
}

extension HotUserWalletModel: MainHeaderUserWalletStateInfoProvider {
    var isUserWalletLocked: Bool { false }

    var isTokensListEmpty: Bool { userTokenListManager.userTokensList.entries.isEmpty }

    var hasImportedWallets: Bool {
        keysRepository.keys.contains(where: { $0.isImported ?? false })
    }
}

extension HotUserWalletModel: DerivationManagerDelegate {
    func onDerived(_ response: DerivationResult) {
        // tmp sync
        for updatedWallet in response {
            for derivedKey in updatedWallet.value.keys {
//                hotWalletInfo.wallets[updatedWallet.key]?.derivedKeys[derivedKey.key] = derivedKey.value
            }
        }

        userWalletRepository.save()
    }
}

extension HotUserWalletModel: KeysDerivingProvider {
    var keysDerivingInteractor: KeysDeriving {
        fatalError("use HotWalletKeyDerivingInteractor when merged")
    }
}

extension HotUserWalletModel: TotalBalanceProviding {
    var totalBalance: TotalBalanceState {
        totalBalanceProvider.totalBalance
    }

    var totalBalancePublisher: AnyPublisher<TotalBalanceState, Never> {
        totalBalanceProvider.totalBalancePublisher
    }
}

extension HotUserWalletModel: AnalyticsContextDataProvider {
    var analyticsContextData: AnalyticsContextData {
        fatalError("Create analytics context data from the hot wallet")
    }
}

extension HotUserWalletModel: UserWalletSerializable {
    func serialize() -> StoredUserWallet {
        let name = name.isEmpty ? config.name : name

        let newStoredUserWallet = StoredUserWallet(
            userWalletId: userWalletId.value,
            name: name,
            walletInfo: .hotWallet(hotWalletInfo),
            associatedCardIds: [],
            walletData: .none
        )

        return newStoredUserWallet
    }
}
