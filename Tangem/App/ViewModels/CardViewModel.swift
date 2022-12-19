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
    @Injected(\.appWarningsService) private var warningsService: AppWarningsProviding
    @Injected(\.tangemSdkProvider) private var tangemSdkProvider: TangemSdkProviding
    @Injected(\.tangemApiService) var tangemApiService: TangemApiService
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    @Published private(set) var currentSecurityOption: SecurityModeOption = .longTap

    var signer: TangemSigner { _signer }

    var cardId: String { cardInfo.card.cardId }

    var card: CardDTO {
        cardInfo.card
    }

    var walletData: DefaultWalletData {
        cardInfo.walletData
    }

    var batchId: String { cardInfo.card.batchId }
    var cardPublicKey: Data { cardInfo.card.cardPublicKey }
    var derivationStyle: DerivationStyle? {
        cardInfo.card.derivationStyle
    }

    var supportsOnlineImage: Bool {
        config.hasFeature(.onlineImage)
    }

    var isMultiWallet: Bool {
        config.hasFeature(.multiCurrency)
    }

    var emailData: [EmailCollectedData] {
        var data = config.emailData

        if let userWalletId {
            let userWalletIdItem = EmailCollectedData(type: .card(.userWalletId), data: userWalletId.hexString)
            data.append(userWalletIdItem)
        }

        return data
    }

    var emailConfig: EmailConfig? {
        config.emailConfig
    }

    var cardsCount: Int {
        config.cardsCount
    }

    var cardIdFormatted: String {
        cardInfo.cardIdFormatted
    }

    var cardIssuer: String {
        cardInfo.card.issuer.name
    }

    var cardSignedHashes: Int {
        cardInfo.card.walletSignedHashes
    }

    var artworkInfo: ArtworkInfo? {
        CardImageProvider().cardArtwork(for: cardInfo.card.cardId)?.artworkInfo
    }

    var name: String {
        cardInfo.name
    }

    var defaultName: String {
        config.cardName
    }

    var canCreateBackup: Bool {
        !config.getFeatureAvailability(.backup).isHidden
    }

    var canTwin: Bool {
        config.hasFeature(.twinning)
    }

    var hasBackupCards: Bool {
        cardInfo.card.backupStatus?.isActive ?? false
    }

    var shouldShowWC: Bool {
        !config.getFeatureAvailability(.walletConnect).isHidden
    }

    var cardTouURL: URL {
        config.touURL
    }

    var supportsWalletConnect: Bool {
        config.hasFeature(.walletConnect)
    }

    var hasTokenSynchronization: Bool {
        config.hasFeature(.tokenSynchronization)
    }

    // Temp for WC. Migrate to userWalletId?
    var secp256k1SeedKey: Data? {
        cardInfo.card.wallets.first(where: { $0.curve == .secp256k1 })?.publicKey
    }

    private(set) var userWalletId: Data?

    // Separate UserWalletModel and CardViewModel
    var userWalletModel: UserWalletModel?

    private(set) var cardInfo: CardInfo
    private let stateUpdateQueue = DispatchQueue(label: "state_update_queue")
    private var tangemSdk: TangemSdk { tangemSdkProvider.sdk }
    private var config: UserWalletConfig

    var availableSecurityOptions: [SecurityModeOption] {
        var options: [SecurityModeOption] = []

        if canSetLongTap || currentSecurityOption == .longTap {
            options.append(.longTap)
        }

        if config.hasFeature(.accessCode) || currentSecurityOption == .accessCode {
            options.append(.accessCode)
        }

        if config.hasFeature(.passcode) || currentSecurityOption == .passCode {
            options.append(.passCode)
        }

        return options
    }

    var hdWalletsSupported: Bool {
        config.hasFeature(.hdWallets)
    }

    var walletModels: [WalletModel] {
        userWalletModel?.getWalletModels() ?? []
    }

    var wallets: [Wallet] {
        walletModels.map { $0.wallet }
    }

    var canSetLongTap: Bool {
        config.hasFeature(.longTap)
    }

    var longHashesSupported: Bool {
        config.hasFeature(.longHashes)
    }

    var canSend: Bool {
        config.hasFeature(.send)
    }

    var cardAmountType: Amount.AmountType {
        config.cardAmountType
    }

    var supportChatEnvironment: SupportChatEnvironment {
        config.supportChatEnvironment
    }

    var hasWallet: Bool {
        !walletModels.isEmpty
    }

    var cardSetLabel: String? {
        config.cardSetLabel
    }

    var canShowAddress: Bool {
        config.hasFeature(.receive)
    }

    var canShowSend: Bool {
        config.hasFeature(.withdrawal)
    }

    var supportedBlockchains: Set<Blockchain> {
        config.supportedBlockchains
    }

    var backupInput: OnboardingInput? {
        guard let backupSteps = config.backupSteps else { return nil }

        return OnboardingInput(steps: backupSteps,
                               cardInput: .cardModel(self),
                               welcomeStep: nil,
                               twinData: nil,
                               currentStepIndex: 0,
                               isStandalone: true)
    }

    var onboardingInput: OnboardingInput {
        OnboardingInput(steps: config.onboardingSteps,
                        cardInput: .cardModel(self),
                        welcomeStep: nil,
                        twinData: cardInfo.walletData.twinData,
                        currentStepIndex: 0)
    }

    var twinInput: OnboardingInput? {
        guard config.hasFeature(.twinning) else { return nil }


        return OnboardingInput(
            steps: .twins(TwinsOnboardingStep.twinningSteps),
            cardInput: .cardModel(self),
            welcomeStep: nil,
            twinData: cardInfo.walletData.twinData,
            currentStepIndex: 0,
            isStandalone: true)
    }

    var resetToFactoryAvailability: UserWalletFeature.Availability {
        config.getFeatureAvailability(.resetToFactory)
    }

    var shouldShowLegacyDerivationAlert: Bool {
        config.warningEvents.contains(where: { $0 == .legacyDerivation })
    }

    var canExchangeCrypto: Bool { !config.getFeatureAvailability(.exchange).isHidden }

    var userWallet: UserWallet? {
        userWalletModel?.userWallet
    }

    private var isActive: Bool {
        if let selectedUserWalletId = userWalletRepository.selectedUserWalletId {
            return selectedUserWalletId == userWalletId
        } else {
            return true
        }
    }

    private var searchBlockchainsCancellable: AnyCancellable? = nil
    private var bag = Set<AnyCancellable>()
    private var signSubscription: AnyCancellable?

    private var _signer: TangemSigner {
        didSet {
            signSubscription = _signer.signPublisher
                .sink { [weak self] card in // [REDACTED_TODO_COMMENT]
                    self?.onSigned(card)
                }
        }
    }

    convenience init(userWallet: UserWallet) {
        let cardInfo = userWallet.cardInfo()
        let config = UserWalletConfigFactory(cardInfo).makeConfig()

        self.init(cardInfo: cardInfo, config: config, userWallet: userWallet)
    }

    init(
        cardInfo: CardInfo,
        config: UserWalletConfig,
        userWallet: UserWallet? = nil
    ) {
        self.cardInfo = cardInfo
        self.config = config
        self._signer = config.tangemSigner
        createUserWalletModelIfNeeded(with: userWallet)
        updateCurrentSecurityOption()
        appendPersistentBlockchains()
        bind()
    }

    func setupWarnings() {
        warningsService.setupWarnings(
            for: config,
            card: cardInfo.card,
            validator: walletModels.first?.walletManager as? SignatureCountValidator
        )
    }

    func appendPersistentBlockchains() {
        guard let persistentBlockchains = config.persistentBlockchains else {
            return
        }

        userWalletModel?.append(entries: persistentBlockchains)
    }

    func appendDefaultBlockchains() {
        userWalletModel?.append(entries: config.defaultBlockchains)
    }

    func deriveEntriesWithoutDerivation() {
        guard let userWalletModel = userWalletModel else {
            assertionFailure("UserWalletModel not created")
            return
        }

        derive(entries: userWalletModel.getEntriesWithoutDerivation()) { [weak self] result in
            switch result {
            case .success:
                self?.userWalletModel?.updateAndReloadWalletModels()
            case .failure:
                print("Derivation error")
            }
        }
    }

    // MARK: - Security

    func changeSecurityOption(_ option: SecurityModeOption, completion: @escaping (Result<Void, Error>) -> Void) {
        switch option {
        case .accessCode:
            tangemSdk.startSession(with: SetUserCodeCommand(accessCode: nil),
                                   cardId: cardId,
                                   initialMessage: Message(header: nil, body: "initial_message_change_access_code_body".localized)) { [weak self] result in
                guard let self = self else { return }

                switch result {
                case .success:
                    self.onSecurityOptionChanged(isAccessCodeSet: true, isPasscodeSet: false)
                    Analytics.log(.userCodeChanged)
                    completion(.success(()))
                case .failure(let error):
                    Analytics.logCardSdkError(error, for: .changeSecOptions, card: self.cardInfo.card, parameters: [.newSecOption: "Access Code"])
                    completion(.failure(error))
                }
            }
        case .longTap:
            tangemSdk.startSession(with: SetUserCodeCommand.resetUserCodes,
                                   cardId: cardId) { [weak self] result in
                guard let self = self else { return }

                switch result {
                case .success:
                    self.onSecurityOptionChanged(isAccessCodeSet: false, isPasscodeSet: false)
                    completion(.success(()))
                case .failure(let error):
                    Analytics.logCardSdkError(error, for: .changeSecOptions, card: self.cardInfo.card, parameters: [.newSecOption: "Long tap"])
                    completion(.failure(error))
                }
            }
        case .passCode:
            tangemSdk.startSession(with: SetUserCodeCommand(passcode: nil),
                                   cardId: cardId,
                                   initialMessage: Message(header: nil, body: "initial_message_change_passcode_body".localized)) { [weak self] result in
                guard let self = self else { return }

                switch result {
                case .success:
                    self.onSecurityOptionChanged(isAccessCodeSet: false, isPasscodeSet: true)
                    completion(.success(()))
                case .failure(let error):
                    Analytics.logCardSdkError(error, for: .changeSecOptions, card: self.cardInfo.card, parameters: [.newSecOption: "Pass code"])
                    completion(.failure(error))
                }
            }
        }
    }

    // MARK: - Wallet

    func createWallet(_ completion: @escaping (Result<Void, Error>) -> Void) {
        let card = self.cardInfo.card
        tangemSdk.startSession(with: CreateWalletAndReadTask(with: config.defaultCurve),
                               cardId: cardId,
                               initialMessage: Message(header: nil,
                                                       body: "initial_message_create_wallet_body".localized)) { [weak self] result in
            switch result {
            case .success(let card):
                self?.onWalletCreated(card)
                completion(.success(()))
            case .failure(let error):
                Analytics.logCardSdkError(error, for: .createWallet, card: card)
                completion(.failure(error))
            }
        }
    }

    func resetToFactory(completion: @escaping (Result<Void, TangemSdkError>) -> Void) {
        let card = self.cardInfo.card
        tangemSdk.startSession(with: ResetToFactorySettingsTask(),
                               cardId: cardId,
                               initialMessage: Message(header: nil,
                                                       body: "initial_message_purge_wallet_body".localized)) { [weak self] result in
            switch result {
            case .success:
                Analytics.log(.factoryResetFinished)
                self?.clearTwinPairKey()
                completion(.success(()))
            case .failure(let error):
                Analytics.logCardSdkError(error, for: .purgeWallet, card: card)
                completion(.failure(error))
            }
        }
    }

    func getBlockchainNetwork(for blockchain: Blockchain, derivationPath: DerivationPath?) -> BlockchainNetwork {
        if let derivationPath = derivationPath {
            return BlockchainNetwork(blockchain, derivationPath: derivationPath)
        }

        if let derivationStyle = cardInfo.card.derivationStyle {
            let derivationPath = blockchain.derivationPath(for: derivationStyle)
            return BlockchainNetwork(blockchain, derivationPath: derivationPath)
        }

        return BlockchainNetwork(blockchain, derivationPath: nil)
    }

    func setUserWallet(_ userWallet: UserWallet) {
        cardInfo = userWallet.cardInfo()
        userWalletModel?.updateUserWallet(userWallet)
    }

    // MARK: - Update

    func onWalletCreated(_ card: Card) {
        cardInfo.card.wallets = card.wallets
        onUpdate()
    }

    func onSecurityOptionChanged(isAccessCodeSet: Bool, isPasscodeSet: Bool) {
        cardInfo.card.isAccessCodeSet = isAccessCodeSet
        cardInfo.card.isPasscodeSet = isPasscodeSet
        onUpdate()
    }

    func onSigned(_ card: Card) {
        for updatedWallet in card.wallets {
            cardInfo.card.wallets[updatedWallet.publicKey]?.totalSignedHashes = updatedWallet.totalSignedHashes
            cardInfo.card.wallets[updatedWallet.publicKey]?.remainingSignatures = updatedWallet.remainingSignatures
        }

        onUpdate()
    }

    func onDerived(_ response: DerivationResult) {
        for updatedWallet in response {
            for derivedKey in updatedWallet.value {
                cardInfo.card.wallets[updatedWallet.key]?.derivedKeys[derivedKey.key] = derivedKey.value
            }
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

    func onTwinWalletCreated(_ walletData: DefaultWalletData) { // [REDACTED_TODO_COMMENT]
        self.cardInfo.walletData = walletData
        onUpdate()
    }

    private func onUpdate() {
        print("🔄 Updating CardViewModel with new Card")
        config = UserWalletConfigFactory(cardInfo).makeConfig()
        _signer = config.tangemSigner
        updateModel()
        updateUserWallet()
    }

    func clearTwinPairKey() { // [REDACTED_TODO_COMMENT]
        if case let .twin(walletData, twinData) = cardInfo.walletData {
            let newData = TwinData(series: twinData.series)
            cardInfo.walletData = .twin(walletData, newData)
        }
    }

    func logSdkError(_ error: Error, action: Analytics.Action, parameters: [Analytics.ParameterKey: String] = [:]) {
        Analytics.logCardSdkError(error.toTangemSdkError(), for: action, card: cardInfo.card, parameters: parameters)
    }

    func didScan() {
        Analytics.logScan(card: cardInfo.card, config: config)
    }

    func getDisabledLocalizedReason(for feature: UserWalletFeature) -> String? {
        config.getFeatureAvailability(feature).disabledLocalizedReason
    }

    func updateSdkConfig() {
        var config = config.sdkConfig
        config.accessCodeRequestPolicy = accessCodeRequestPolicy()

        tangemSdkProvider.setup(with: config)
    }

    private func accessCodeRequestPolicy() -> AccessCodeRequestPolicy {
        let hasCode = card.isAccessCodeSet

        if !AppSettings.shared.saveUserWallets {
            return hasCode ? .always : .default
        }

        if hasCode {
            return AppSettings.shared.saveAccessCodes ? .alwaysWithBiometrics : .always
        }

        return .default
    }

    private func updateModel() {
        print("🔄 Updating Card view model")
        updateCurrentSecurityOption()

        setupWarnings()
        createUserWalletModelIfNeeded()
        userWalletModel?.updateUserWalletModel(with: config)

        if let userWallet = userWallet {
            userWalletModel?.updateUserWallet(userWallet)
        }
    }

    private func searchBlockchains() {
        guard config.hasFeature(.tokensSearch) else { return }

        searchBlockchainsCancellable = nil

        let currentBlockhains = wallets.map { $0.blockchain }
        let unused: [StorageEntry] = config.supportedBlockchains
            .subtracting(currentBlockhains)
            .map { StorageEntry(blockchainNetwork: .init($0, derivationPath: nil), tokens: []) }

        let models = unused.compactMap {
            try? config.makeWalletModel(for: $0)
        }

        if models.isEmpty {
            return
        }

        searchBlockchainsCancellable = Publishers.MergeMany(
            models.map { $0.update(silent: false) }
        )
        .collect()
        .receiveCompletion { [weak self] _ in
            guard let self = self else { return }

            let notEmptyWallets = models.filter { !$0.wallet.isEmpty }
            if !notEmptyWallets.isEmpty {
                let entries = notEmptyWallets.map {
                    StorageEntry(blockchainNetwork: $0.blockchainNetwork, tokens: [])
                }

                // [REDACTED_TODO_COMMENT]
                self.add(entries: entries) { _ in }
            }
        }
    }

    private func searchTokens() {
        guard config.hasFeature(.tokensSearch),
              !AppSettings.shared.searchedCards.contains(cardId) else {
            return
        }

        guard let ethBlockchain = config.supportedBlockchains.first(where: {
            if case .ethereum = $0 {
                return true
            }

            return false
        }) else {
            return
        }

        var shouldAddWalletManager = false
        let network = getBlockchainNetwork(for: ethBlockchain, derivationPath: nil)
        var ethWalletModel = walletModels.first(where: { $0.blockchainNetwork == network })

        if ethWalletModel == nil {
            shouldAddWalletManager = true
            let entry = StorageEntry(blockchainNetwork: network, tokens: [])
            ethWalletModel = try? config.makeWalletModel(for: entry)
        }

        guard let ethWalletModel = ethWalletModel,
              let tokenFinder = ethWalletModel.walletManager as? TokenFinder else {
            AppSettings.shared.searchedCards.append(self.cardId)
            self.searchBlockchains()
            return
        }

        tokenFinder.findErc20Tokens(knownTokens: []) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let tokensAdded):
                if tokensAdded, shouldAddWalletManager {
                    let tokens = ethWalletModel.walletManager.cardTokens
                    let entry = StorageEntry(blockchainNetwork: network, tokens: tokens)
                    // [REDACTED_TODO_COMMENT]
                    self.add(entries: [entry]) { _ in }
                }
            case .failure(let error):
                print(error)
            }

            AppSettings.shared.searchedCards.append(self.cardId)
            self.searchBlockchains()
        }
    }

    private func updateCurrentSecurityOption() {
        if cardInfo.card.isAccessCodeSet {
            self.currentSecurityOption = .accessCode
        } else if (cardInfo.card.isPasscodeSet ?? false) {
            self.currentSecurityOption = .passCode
        } else {
            self.currentSecurityOption = .longTap
        }
    }

    private func bind() {
        AppSettings.shared.$saveUserWallets
            .combineLatest(AppSettings.shared.$saveAccessCodes)
            .sink { [weak self] _ in
                guard let self else { return }

                if self.isActive {
                    self.updateSdkConfig()
                }
            }
            .store(in: &bag)
    }

    private func updateUserWallet() {
        guard let userWallet = UserWalletFactory().userWallet(from: self) else { return }

        userWalletModel?.updateUserWallet(userWallet)

        if userWalletRepository.contains(userWallet) {
            userWalletRepository.save(userWallet)
        }
    }

    private func createUserWalletModelIfNeeded(with savedUserWallet: UserWallet? = nil) {
        let userWallet: UserWallet

        if let savedUserWallet = savedUserWallet {
            userWallet = savedUserWallet
        } else if userWalletModel == nil,
                  cardInfo.card.hasWallets,
                  let newUserWallet = UserWalletFactory().userWallet(from: cardInfo, config: config) {
            userWallet = newUserWallet
        } else {
            return
        }

        self.userWalletId = userWallet.userWalletId
        userWalletModel = CommonUserWalletModel(config: config, userWallet: userWallet)
    }
}

// MARK: - Proxy for User Wallet Model

extension CardViewModel {
    func subscribeWalletModels() -> AnyPublisher<[WalletModel], Never> {
        guard let userWalletModel = userWalletModel else {
            assertionFailure("UserWalletModel not created")
            return Just([]).eraseToAnyPublisher()
        }

        return userWalletModel.subscribeToWalletModels()
    }

    func add(entries: [StorageEntry], completion: @escaping (Result<Void, Error>) -> Void) {
        derive(entries: entries) { [weak self] result in
            switch result {
            case .success:
                self?.userWalletModel?.append(entries: entries)
                self?.userWalletModel?.updateAndReloadWalletModels()
                completion(.success(()))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    func update(entries: [StorageEntry], completion: @escaping (Result<Void, Error>) -> Void) {
        derive(entries: entries) { [weak self] result in
            switch result {
            case .success:
                self?.userWalletModel?.update(entries: entries)
                self?.userWalletModel?.updateAndReloadWalletModels()
                completion(.success(()))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    func derive(entries: [StorageEntry], completion: @escaping (Result<Void, Error>) -> Void) {
        let derivationManager = DerivationManager(config: config, cardInfo: cardInfo)
        let alreadySaved = userWalletModel?.getSavedEntries() ?? []
        derivationManager.deriveIfNeeded(entries: alreadySaved + entries, completion: { [weak self] result in
            switch result {
            case let .success(response):
                if let response {
                    self?.onDerived(response)
                }

                completion(.success(()))
            case let .failure(error):
                completion(.failure(error))
            }
        })
    }

    func canManage(amountType: Amount.AmountType, blockchainNetwork: BlockchainNetwork) -> Bool {
        guard let userWalletModel = userWalletModel else {
            assertionFailure("UserWalletModel not created")
            return false
        }

        return userWalletModel.canManage(amountType: amountType, blockchainNetwork: blockchainNetwork)
    }
}

extension CardViewModel {
    enum WalletsBalanceState {
        case inProgress
        case loaded
    }
}
