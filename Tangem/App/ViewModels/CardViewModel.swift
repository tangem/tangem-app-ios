//
//  CardViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk
import Combine
import Alamofire
import SwiftUI

class CardViewModel: Identifiable, ObservableObject {
    // MARK: Services

    @Injected(\.tangemApiService) var tangemApiService: TangemApiService
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    let walletModelsManager: WalletModelsManager

    var userTokensManager: UserTokensManager { _userTokensManager }

    private lazy var _userTokensManager = CommonUserTokensManager(
        userWalletId: userWalletId,
        shouldLoadSwapAvailability: config.hasFeature(.swapping),
        userTokenListManager: userTokenListManager,
        walletModelsManager: walletModelsManager,
        derivationStyle: config.derivationStyle,
        derivationManager: derivationManager,
        keysDerivingProvider: self,
        existingCurves: config.walletCurves,
        longHashesSupported: config.hasFeature(.longHashes)
    )

    let userTokenListManager: UserTokenListManager

    private let keysRepository: KeysRepository
    private let walletManagersRepository: WalletManagersRepository
    private let cardImageProvider = CardImageProvider()

    lazy var derivationManager: DerivationManager? = {
        guard config.hasFeature(.hdWallets) else {
            return nil
        }

        let commonDerivationManager = CommonDerivationManager(
            keysRepository: keysRepository,
            userTokenListManager: userTokenListManager
        )

        commonDerivationManager.delegate = self
        return commonDerivationManager
    }()

    let warningsService = WarningsService()

    var signer: TangemSigner { _signer }

    var cardId: String { cardInfo.card.cardId }

    var card: CardDTO {
        cardInfo.card
    }

    var cardPublicKey: Data { cardInfo.card.cardPublicKey }

    var supportsOnlineImage: Bool {
        config.hasFeature(.onlineImage)
    }

    var emailConfig: EmailConfig? {
        config.emailConfig
    }

    var name: String {
        cardInfo.name
    }

    var canSkipBackup: Bool {
        config.canSkipBackup
    }

    var hasBackupCards: Bool {
        cardInfo.card.backupStatus?.isActive ?? false
    }

    var cardDisclaimer: TOU {
        config.tou
    }

    let userWalletId: UserWalletId

    lazy var totalBalanceProvider: TotalBalanceProviding = TotalBalanceProvider(
        userWalletId: userWalletId,
        walletModelsManager: walletModelsManager,
        derivationManager: derivationManager
    )

    private(set) var cardInfo: CardInfo
    private var tangemSdk: TangemSdk?
    var config: UserWalletConfig

    var userWallet: UserWallet {
        UserWalletFactory().userWallet(from: cardInfo, config: config, userWalletId: userWalletId)
    }

    private var isActive: Bool {
        if let selectedUserWalletId = userWalletRepository.selectedUserWalletId {
            return selectedUserWalletId == userWalletId.value
        } else {
            return true
        }
    }

    private let _updatePublisher: PassthroughSubject<Void, Never> = .init()
    private let _userWalletNamePublisher: CurrentValueSubject<String, Never>
    private let _cardHeaderImagePublisher: CurrentValueSubject<ImageType?, Never>
    private var bag = Set<AnyCancellable>()
    private var signSubscription: AnyCancellable?

    private var _signer: TangemSigner {
        didSet {
            bindSigner()
        }
    }

    convenience init?(userWallet: UserWallet) {
        let cardInfo = userWallet.cardInfo()
        self.init(cardInfo: cardInfo)
    }

    init?(cardInfo: CardInfo) {
        let config = UserWalletConfigFactory(cardInfo).makeConfig()

        guard let userWalletIdSeed = config.userWalletIdSeed,
              let walletManagerFactory = try? config.makeAnyWalletManagerFactory() else {
            return nil
        }

        self.cardInfo = cardInfo
        self.config = config
        keysRepository = CommonKeysRepository(with: cardInfo.card.wallets)

        userWalletId = UserWalletId(with: userWalletIdSeed)
        userTokenListManager = CommonUserTokenListManager(
            userWalletId: userWalletId.value,
            supportedBlockchains: config.supportedBlockchains,
            hdWalletsSupported: config.hasFeature(.hdWallets),
            hasTokenSynchronization: config.hasFeature(.tokenSynchronization),
            defaultBlockchains: config.defaultBlockchains
        )

        walletManagersRepository = CommonWalletManagersRepository(
            keysProvider: keysRepository,
            userTokenListManager: userTokenListManager,
            walletManagerFactory: walletManagerFactory
        )

        walletModelsManager = CommonWalletModelsManager(
            walletManagersRepository: walletManagersRepository,
            walletModelsFactory: config.makeWalletModelsFactory()
        )

        _signer = config.tangemSigner
        _userWalletNamePublisher = .init(cardInfo.name)
        _cardHeaderImagePublisher = .init(config.cardHeaderImage)
        appendPersistentBlockchains()
        bind()

        userTokensManager.sync {}
    }

    deinit {
        Log.debug("CardViewModel deinit 🥳🤟")
    }

    func setupWarnings() {
        warningsService.setupWarnings(
            for: config,
            card: cardInfo.card,
            validator: walletModelsManager.walletModels.first?.signatureCountValidator
        )
    }

    func validate() -> Bool {
        var expectedCurves = config.mandatoryCurves
        /// Since the curve `bls12381_G2_AUG` was added later into first generation of wallets,, we cannot determine whether this curve is missing due to an error or because the user did not want to recreate the wallet.
        if config is GenericConfig {
            expectedCurves.remove(.bls12381_G2_AUG)
        }

        let curvesValidator = CurvesValidator(expectedCurves: expectedCurves)
        if !curvesValidator.validate(card.wallets.map { $0.curve }) {
            return false
        }

        let backupValidator = BackupValidator()
        if !backupValidator.validate(backupStatus: card.backupStatus, wallets: cardInfo.card.wallets) {
            return false
        }

        return true
    }

    private func appendPersistentBlockchains() {
        guard let persistentBlockchains = config.persistentBlockchains else {
            return
        }

        userTokenListManager.update(.append(persistentBlockchains), shouldUpload: true)
    }

    // MARK: - Update

    func onSigned(_ card: Card) {
        for updatedWallet in card.wallets {
            cardInfo.card.wallets[updatedWallet.publicKey]?.totalSignedHashes = updatedWallet.totalSignedHashes
            cardInfo.card.wallets[updatedWallet.publicKey]?.remainingSignatures = updatedWallet.remainingSignatures
        }

        onUpdate()
    }

    func onBackupCreated(_ card: Card) {
        for updatedWallet in card.wallets {
            cardInfo.card.wallets[updatedWallet.publicKey]?.hasBackup = updatedWallet.hasBackup
        }

        cardInfo.card.settings = CardDTO.Settings(settings: card.settings)
        cardInfo.card.isAccessCodeSet = card.isAccessCodeSet
        cardInfo.card.backupStatus = card.backupStatus
        onUpdate()
    }

    private func onUpdate() {
        AppLog.shared.debug("🔄 Updating CardViewModel with new Card")
        config = UserWalletConfigFactory(cardInfo).makeConfig()
        _cardHeaderImagePublisher.send(config.cardHeaderImage)
        _signer = config.tangemSigner
        updateModel()
        // prevent save until onboarding completed
        if userWalletRepository.contains(userWallet) {
            userWalletRepository.save(userWallet)
        }
        _updatePublisher.send()
    }

    private func updateModel() {
        AppLog.shared.debug("🔄 Updating Card view model")
        setupWarnings()
    }

    private func bind() {
        bindSigner()
    }

    private func bindSigner() {
        signSubscription = _signer.signPublisher
            .sink { [weak self] card in // [REDACTED_TODO_COMMENT]
                self?.onSigned(card)
            }
    }
}

extension CardViewModel {
    enum WalletsBalanceState {
        case inProgress
        case loaded
    }
}

extension CardViewModel: WalletConnectUserWalletInfoProvider {
    var wcWalletModelProvider: WalletConnectWalletModelProvider {
        CommonWalletConnectWalletModelProvider(walletModelsManager: walletModelsManager)
    }
}

// [REDACTED_TODO_COMMENT]
extension CardViewModel: TangemSdkFactory {
    func makeTangemSdk() -> TangemSdk {
        config.makeTangemSdk()
    }
}

// MARK: - UserWalletModel

extension CardViewModel: UserWalletModel {
    var cardsCount: Int {
        config.cardsCount
    }

    var emailData: [EmailCollectedData] {
        var data = config.emailData

        let userWalletIdItem = EmailCollectedData(type: .card(.userWalletId), data: userWalletId.stringValue)
        data.append(userWalletIdItem)

        return data
    }

    var backupInput: OnboardingInput? {
        let factory = OnboardingInputFactory(
            cardInfo: cardInfo,
            cardModel: self,
            sdkFactory: config,
            onboardingStepsBuilderFactory: config
        )

        return factory.makeBackupInput()
    }

    var twinInput: OnboardingInput? {
        guard let twinData = cardInfo.walletData.twinData else {
            return nil
        }

        let factory = TwinInputFactory(
            cardInput: .cardModel(self),
            userWalletToDelete: userWallet,
            twinData: twinData,
            sdkFactory: config
        )
        return factory.makeTwinInput()
    }

    var updatePublisher: AnyPublisher<Void, Never> {
        _updatePublisher.eraseToAnyPublisher()
    }

    var tokensCount: Int? {
        walletModelsManager.walletModels.count
    }

    var cardImagePublisher: AnyPublisher<CardImageResult, Never> {
        let artwork: CardArtwork

        if let artworkInfo = cardImageProvider.cardArtwork(for: cardInfo.card.cardId)?.artworkInfo {
            artwork = .artwork(artworkInfo)
        } else {
            artwork = .notLoaded
        }

        return cardImageProvider.loadImage(
            cardId: card.cardId,
            cardPublicKey: card.cardPublicKey,
            artwork: artwork
        )
    }

    func updateWalletName(_ name: String) {
        cardInfo.name = name
        _userWalletNamePublisher.send(name)
    }
}

extension CardViewModel: MainHeaderSupplementInfoProvider {
    var cardHeaderImagePublisher: AnyPublisher<ImageType?, Never> { _cardHeaderImagePublisher.removeDuplicates().eraseToAnyPublisher() }

    var userWalletNamePublisher: AnyPublisher<String, Never> { _userWalletNamePublisher.eraseToAnyPublisher() }
}

extension CardViewModel: MainHeaderUserWalletStateInfoProvider {
    var isUserWalletLocked: Bool { userWallet.isLocked }

    var isTokensListEmpty: Bool { userTokenListManager.userTokensList.entries.isEmpty }
}

// [REDACTED_TODO_COMMENT]
extension CardViewModel: DerivationManagerDelegate {
    func onDerived(_ response: DerivationResult) {
        // tmp sync
        for updatedWallet in response {
            for derivedKey in updatedWallet.value.keys {
                cardInfo.card.wallets[updatedWallet.key]?.derivedKeys[derivedKey.key] = derivedKey.value
            }
        }

        userWalletRepository.save(userWallet)
    }
}

extension CardViewModel: KeysDerivingProvider {
    var keysDerivingInteractor: KeysDeriving {
        KeysDerivingCardInteractor(with: cardInfo)
    }
}

extension CardViewModel: TotalBalanceProviding {
    var totalBalancePublisher: AnyPublisher<LoadingValue<TotalBalance>, Never> {
        totalBalanceProvider.totalBalancePublisher
    }
}

extension CardViewModel: AnalyticsContextDataProvider {
    func getAnalyticsContextData() -> AnalyticsContextData? {
        return AnalyticsContextData(
            card: card,
            productType: config.productType,
            embeddedEntry: config.embeddedBlockchain
        )
    }
}

extension CardViewModel: EmailDataProvider {}
