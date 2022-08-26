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

struct CardPinSettings {
    var isPin1Default: Bool? = nil
    var isPin2Default: Bool? = nil
}

class CardViewModel: Identifiable, ObservableObject {
    // MARK: Services
    @Injected(\.cardImageLoader) var imageLoader: CardImageLoaderProtocol
    @Injected(\.appWarningsService) private var warningsService: AppWarningsProviding
    @Injected(\.tangemSdkProvider) private var tangemSdkProvider: TangemSdkProviding
    @Injected(\.tangemApiService) var tangemApiService: TangemApiService
    @Injected(\.userWalletListService) private var userWalletListService: UserWalletListService

    @Published var state: State = .created
    @Published private(set) var currentSecurityOption: SecurityModeOption = .longTap
    @Published var walletsBalanceState: WalletsBalanceState = .loaded
    @Published var totalBalance: String? = nil
    @Published var cardImage: UIImage?

    var signer: TangemSigner { config.tangemSigner }

    var cardId: String { cardInfo.card.cardId }

    var card: CardDTO {
        cardInfo.card
    }

    var walletData: DefaultWalletData {
        cardInfo.walletData
    }

    var isMultiWallet: Bool {
        config.hasFeature(.multiCurrency)
    }

    var emailData: [EmailCollectedData] {
        config.emailData
    }

    var emailConfig: EmailConfig {
        config.emailConfig
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
        cardInfo.artworkInfo
    }

    var name: String {
        cardInfo.name
    }

    var defaultName: String {
        config.cardName
    }

    var canCreateBackup: Bool {
        config.hasFeature(.backup)
    }

    var canTwin: Bool {
        config.hasFeature(.twinning)
    }

    var shouldShowWC: Bool {
        !config.getFeatureAvailability(.walletConnect).isHidden
    }

    var cardTouURL: URL? {
        config.touURL
    }

    var canCountHashes: Bool {
        config.hasFeature(.signedHashesCounter)
    }

    var supportsWalletConnect: Bool {
        config.hasFeature(.walletConnect)
    }

    // Temp for WC. Migrate to userWalletId?
    var secp256k1SeedKey: Data? {
        cardInfo.card.wallets.first(where: { $0.curve == .secp256k1 })?.publicKey
    }

    private var cardInfo: CardInfo
    private var walletBalanceSubscription: AnyCancellable? = nil
    private var cardPinSettings: CardPinSettings = CardPinSettings()
    private let stateUpdateQueue = DispatchQueue(label: "state_update_queue")
    private var migrated = false
    private var tangemSdk: TangemSdk { tangemSdkProvider.sdk }
    private var config: UserWalletConfig
    private let tokenItemsRepository: TokenItemsRepository

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

    var walletModels: [WalletModel]? {
        state.walletModels
    }

    var wallets: [Wallet]? {
        walletModels?.map { $0.wallet }
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

    var hasWallet: Bool {
        state.walletModels != nil
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


    var isResetToFactoryAvailable: Bool {
        config.hasFeature(.resetToFactory)
    }

    var isSuccesfullyLoaded: Bool {
        if let walletModels = state.walletModels {
            if walletModels.contains(where: { !$0.state.isSuccesfullyLoaded }) {
                return false
            }

            return true
        }

        return false
    }

    var hasBalance: Bool {
        let hasBalance = state.walletModels.map { $0.contains(where: { $0.hasBalance }) } ?? false

        return hasBalance
    }

    var shoulShowLegacyDerivationAlert: Bool {
        config.warningEvents.contains(where: { $0 == .legacyDerivation })
    }

    var canExchangeCrypto: Bool { config.hasFeature(.exchange) }

    var cachedImage: UIImage? = nil

    var imageLoaderPublisher: AnyPublisher<UIImage, Never> {
        if let cached = cachedImage {
            return Just(cached).eraseToAnyPublisher()
        }

        return self.imageLoader
            .loadImage(cid: cardId,
                       cardPublicKey: cardInfo.card.cardPublicKey,
                       artworkInfo: cardInfo.artworkInfo)
            .map { [weak self] (image, canBeCached) -> UIImage in
                if canBeCached {
                    self?.cachedImage = image
                }

                return image
            }
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    var userWallet: UserWallet {
        UserWalletFactory().userWallet(from: self)
    }

    var isUserWalletLocked: Bool {
        return userWallet.isLocked
    }

    var subtitle: String {
        if let embeddedBlockchain = config.embeddedBlockchain {
            return embeddedBlockchain.blockchainNetwork.blockchain.displayName
        }

        let count = config.cardsCount
        switch count {
        case 1:
            return "\(count) Card"
        default:
            return "\(count) Cards"
        }
    }

    var numberOfTokens: String? {
        let tokenRepository = CommonTokenItemsRepository(key: userWallet.card.cardId)
        let tokenItems = tokenRepository.getItems()

        let numberOfBlockchainsPerItem = 1
        let numberOfTokens = tokenItems.reduce(0) { sum, tokenItem in
            sum + numberOfBlockchainsPerItem + tokenItem.tokens.count
        }

        if numberOfTokens == 0 {
            return nil
        }

        return "\(numberOfTokens) tokens"
    }

    private lazy var totalSumBalanceViewModel: TotalSumBalanceViewModel = .init(isSingleCoinCard: !isMultiWallet) { }

    private var searchBlockchainsCancellable: AnyCancellable? = nil
    private var bag = Set<AnyCancellable>()

    convenience init(userWallet: UserWallet) {
        self.init(cardInfo: userWallet.cardInfo())
    }

    init(cardInfo: CardInfo) {
        self.cardInfo = cardInfo
        self.config = UserWalletConfigFactory(cardInfo).makeConfig()
        tokenItemsRepository = CommonTokenItemsRepository(key: cardInfo.card.cardId)

        updateCardPinSettings()
        updateCurrentSecurityOption()
        bind()
    }

    func setupWarnings() {
        warningsService.setupWarnings(for: config)
    }

    func update() -> AnyPublisher<Never, Never> {
        guard state.canUpdate else {
            return Empty().eraseToAnyPublisher()
        }

        observeBalanceLoading()

        return tryMigrateTokens()
            .flatMap { [weak self] in
                Publishers
                    .MergeMany(self?.state.walletModels?.map { $0.update() } ?? [])
                    .collect()
                    .ignoreOutput()
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func refresh() -> AnyPublisher<Never, Never> {
        guard state.canUpdate else {
            return Empty().eraseToAnyPublisher()
        }

        observeBalanceLoading(showProgressLoading: false)

        return tryMigrateTokens()
            .flatMap { [weak self] in
                Publishers
                    .MergeMany(self?.state.walletModels?.map { $0.update() } ?? [])
                    .collect()
                    .ignoreOutput()
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func observeBalanceLoading(showProgressLoading: Bool = true) {
        guard let walletModels = self.state.walletModels else {
            return
        }

        if showProgressLoading {
            self.walletsBalanceState = .inProgress
        }

        walletBalanceSubscription = Publishers.MergeMany(walletModels.map({ $0.update() }))
            .collect()
            .receive(on: RunLoop.main)
            .sink { [unowned self] _ in
                self.walletsBalanceState = .loaded
                self.updateTotalBalanceTokenList()
            }
    }

    func appendDefaultBlockchains() {
        tokenItemsRepository.append(config.defaultBlockchains)
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
                    self.cardPinSettings.isPin1Default = false
                    self.cardPinSettings.isPin2Default = true
                    self.updateCurrentSecurityOption()
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
                    self.cardPinSettings.isPin1Default = true
                    self.cardPinSettings.isPin2Default = true
                    self.updateCurrentSecurityOption()
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
                    self.cardPinSettings.isPin1Default = true
                    self.cardPinSettings.isPin2Default = false
                    self.updateCurrentSecurityOption()
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
                self?.update(with: CardDTO(card: card))
                completion(.success(()))
            case .failure(let error):
                Analytics.logCardSdkError(error, for: .createWallet, card: card)
                completion(.failure(error))
            }
        }
    }

    func resetToFactory(completion: @escaping (Result<Void, Error>) -> Void) {
        let card = self.cardInfo.card
        tangemSdk.startSession(with: ResetToFactorySettingsTask(),
                               cardId: cardId,
                               initialMessage: Message(header: nil,
                                                       body: "initial_message_purge_wallet_body".localized)) { [weak self] result in
            switch result {
            case .success(let response):
                Analytics.log(.factoryResetSuccess)
                self?.tokenItemsRepository.removeAll()
                self?.clearTwinPairKey()
                // self.update(with: response)
                completion(.success(()))
            case .failure(let error):
                Analytics.logCardSdkError(error, for: .purgeWallet, card: card)
                completion(.failure(error))
            }
        }
    }

    func deriveKeys(completion: @escaping (Result<Void, Error>) -> Void) {
        let card = self.cardInfo.card
        let entries = tokenItemsRepository.getItems()
        var derivations: [EllipticCurve: [DerivationPath]] = [:]

        for entry in entries {
            if let path = entry.blockchainNetwork.derivationPath {
                derivations[entry.blockchainNetwork.blockchain.curve, default: []].append(path)
            }
        }

        tangemSdk.config.defaultDerivationPaths = derivations
        tangemSdk.startSession(with: ScanTask(), cardId: card.cardId) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let card):
                self.update(with: CardDTO(card: card))
                completion(.success(()))
            case .failure(let error):
                Analytics.logCardSdkError(error, for: .purgeWallet, card: card)
                completion(.failure(error))
            }
        }
    }

    func getBlockchainNetwork(for blockchain: Blockchain, derivationPath: DerivationPath?) -> BlockchainNetwork {
        let derivationPath = derivationPath ?? blockchain.derivationPath(for: cardInfo.card.derivationStyle)
        return BlockchainNetwork(blockchain, derivationPath: derivationPath)
    }

    func setUserWallet(_ userWallet: UserWallet) {
        cardInfo = userWallet.cardInfo()
    }

    // MARK: - Update

    func getCardInfo() {
        if case .artwork = cardInfo.artwork {
            loadCardImage()
            return
        }

        cardInfo.artwork = .notLoaded
        guard config.hasFeature(.onlineImage) else {
            cardInfo.artwork = .noArtwork
            loadCardImage()
            return
        }

        OnlineCardVerifier()
            .getCardInfo(cardId: cardInfo.card.cardId, cardPublicKey: cardInfo.card.cardPublicKey)
            .receive(on: DispatchQueue.main)
            .sink { receivedCompletion in
                if case .failure = receivedCompletion {
                    self.cardInfo.artwork = .noArtwork
                    self.warningsService.setupWarnings(for: self.config)
                }

                self.loadCardImage()
            } receiveValue: { response in
                guard let artwork = response.artwork else { return }
                self.cardInfo.artwork = .artwork(artwork)
            }
            .store(in: &bag)
    }

    func update(with card: CardDTO) {
        print("🟩 Updating Card view model with new Card")
        cardInfo.card = card // [REDACTED_TODO_COMMENT]
        config = UserWalletConfigFactory(cardInfo).makeConfig()
        updateCardPinSettings()
        updateCurrentSecurityOption()
        updateModel()
        saveUserWallet()
    }

    func update(with cardInfo: CardInfo) {
        print("🔷 Updating Card view model with new CardInfo")
        self.cardInfo = cardInfo
        updateCardPinSettings()
        updateCurrentSecurityOption()
        updateModel()
        saveUserWallet()
    }

    func clearTwinPairKey() { // [REDACTED_TODO_COMMENT]
        if case let .twin(walletData, twinData) = cardInfo.walletData {
            let newData = TwinData(series: twinData.series)
            cardInfo.walletData = .twin(walletData, newData)
        }
    }

    func updateState() {
        print("‼️ Updating Card view model state")
        let hasWallets = !cardInfo.card.wallets.isEmpty

        if !hasWallets {
            self.state = .empty
        } else {
            print("⁉️ Recreating all wallet models for Card view model state")
            self.state = .loaded(walletModel: makeAllWalletModels())

            // [REDACTED_TODO_COMMENT]
            // if !AppSettings.shared.cardsStartedActivation.contains(cardId) || cardInfo.isTangemWallet {
            update()
                .sink { _ in

                } receiveValue: { _ in

                }
                .store(in: &bag)
            //  }
        }
    }

    func logSdkError(_ error: Error, action: Analytics.Action, parameters: [Analytics.ParameterKey: Any] = [:]) {
        Analytics.logCardSdkError(error.toTangemSdkError(), for: action, card: cardInfo.card, parameters: parameters)
    }

    func didScan() {
        Analytics.logScan(card: cardInfo.card, config: config)
        tangemSdkProvider.setup(with: config.sdkConfig)
    }

    func getDisabledLocalizedReason(for feature: UserWalletFeature) -> String? {
        config.getFeatureAvailability(feature).disabledLocalizedReason
    }

    func getLegacyMigrator() -> LegacyCardMigrator? {
        guard config.hasFeature(.multiCurrency) else {
            return nil
        }

        // Check if we have anything to migrate. It's impossible to get default token without default blockchain
        guard let embeddedEntry = config.embeddedBlockchain else {
            return nil
        }

        return .init(cardId: cardId, embeddedEntry: embeddedEntry)
    }

    private func makeAllWalletModels() -> [WalletModel] {
        let tokens = tokenItemsRepository.getItems()
        return config.makeWalletModels(for: tokens)
    }

    private func updateModel() {
        print("🔶 Updating Card view model")
        warningsService.setupWarnings(for: config)
        updateState()
    }

    private func updateLoadedState(with newWalletModels: [WalletModel]) {
        stateUpdateQueue.sync {
            if let existingWalletModels = self.walletModels {
                state = .loaded(walletModel: (existingWalletModels + newWalletModels))
            }
        }
    }

    private func searchBlockchains() {
        guard config.hasFeature(.tokensSearch) else { return }

        searchBlockchainsCancellable = nil

        guard let currentBlockhains = wallets?.map({ $0.blockchain }) else {
            return
        }

        let unused: [StorageEntry] = config.supportedBlockchains
            .subtracting(currentBlockhains).map { StorageEntry(blockchainNetwork: .init($0, derivationPath: nil), tokens: []) }
        let models = config.makeWalletModels(for: unused)
        if models.isEmpty {
            return
        }

        searchBlockchainsCancellable =
            Publishers.MergeMany(models.map { $0.update() })
                .collect(models.count)
                .sink { [weak self] _ in
                    guard let self = self else { return }

                    let notEmptyWallets = models.filter { !$0.wallet.isEmpty }
                    if !notEmptyWallets.isEmpty {
                        let itemsToAdd = notEmptyWallets.map { $0.blockchainNetwork }
                        self.tokenItemsRepository.append(itemsToAdd)
                        self.updateLoadedState(with: notEmptyWallets)
                    }
                } receiveValue: { _ in

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
        var ethWalletModel = walletModels?.first(where: { $0.blockchainNetwork == network })

        if ethWalletModel == nil {
            shouldAddWalletManager = true
            let entry = StorageEntry(blockchainNetwork: network, tokens: [])
            ethWalletModel = config.makeWalletModels(for: [entry]).first
        }

        guard let tokenFinder = ethWalletModel?.walletManager as? TokenFinder else {
            AppSettings.shared.searchedCards.append(self.cardId)
            self.searchBlockchains()
            return
        }


        tokenFinder.findErc20Tokens(knownTokens: []) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let tokensAdded):
                if tokensAdded {
                    let tokens = ethWalletModel!.walletManager.cardTokens
                    self.tokenItemsRepository.append(tokens, blockchainNetwork: network)

                    if shouldAddWalletManager {
                        self.stateUpdateQueue.sync {
                            self.state = .loaded(walletModel: self.walletModels! + [ethWalletModel!])
                        }
                        ethWalletModel!.update()
                    }
                }
            case .failure(let error):
                print(error)
            }

            AppSettings.shared.searchedCards.append(self.cardId)
            self.searchBlockchains()
        }
    }

    func add(items: [(Amount.AmountType, BlockchainNetwork)], completion: @escaping (Result<Void, Error>) -> Void) {
        var entries: [StorageEntry] = []

        items.forEach { item in
            if let index = entries.firstIndex(where: { $0.blockchainNetwork == item.1 }) {
                if let token = item.0.token, !entries[index].tokens.contains(token) {
                    entries[index].tokens.append(token)
                }
            } else {
                let tokens = item.0.token.map { [$0] } ?? []
                entries.append(StorageEntry(blockchainNetwork: item.1, tokens: tokens))
            }
        }

        tokenItemsRepository.append(entries)

        if hdWalletsSupported {
            var shouldDerive: Bool = false

            for entry in entries {
                if let path = entry.blockchainNetwork.derivationPath,
                   let wallet = cardInfo.card.wallets.first(where: { $0.curve == entry.blockchainNetwork.blockchain.curve }),
                   !wallet.derivedKeys.keys.contains(path) {
                    shouldDerive = true
                    break
                }
            }

            if !shouldDerive {
                finishAddingTokens(entries, completion: completion)
                return
            }

            deriveKeys() { result in
                switch result {
                case .success:
                    self.finishAddingTokens(entries, completion: completion)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } else {
            finishAddingTokens(entries, completion: completion)
        }
    }

    private func finishAddingTokens(_ entries: [StorageEntry], completion: @escaping (Result<Void, Error>) -> Void) {
        guard let walletModels = self.walletModels else {
            completion(.success(()))
            return
        }

        var newWalletModels: [WalletModel] = []

        entries.forEach { entry in
            if let existingWalletModel = walletModels.first(where: { $0.blockchainNetwork == entry.blockchainNetwork }) {
                existingWalletModel.addTokens(entry.tokens)
                existingWalletModel.update()
            } else {
                let wm = config.makeWalletModels(for: [entry])
                newWalletModels.append(contentsOf: wm)
            }
        }

        newWalletModels.forEach { $0.update() }
        updateLoadedState(with: newWalletModels)
        completion(.success(()))
    }

    func canManage(amountType: Amount.AmountType, blockchainNetwork: BlockchainNetwork) -> Bool {
        if let walletModel = walletModels?.first(where: { $0.blockchainNetwork == blockchainNetwork }) {
            return walletModel.canRemove(amountType: amountType)
        }

        return true
    }

    func canRemove(amountType: Amount.AmountType, blockchainNetwork: BlockchainNetwork) -> Bool {
        if let walletModel = walletModels?.first(where: { $0.blockchainNetwork == blockchainNetwork }) {
            return walletModel.canRemove(amountType: amountType)
        }

        return false
    }

    func remove(items: [(Amount.AmountType, BlockchainNetwork)]) {
        items.forEach {
            remove(amountType: $0.0, blockchainNetwork: $0.1)
        }
    }

    func remove(amountType: Amount.AmountType, blockchainNetwork: BlockchainNetwork) {
        guard canRemove(amountType: amountType, blockchainNetwork: blockchainNetwork) else {
            assertionFailure("\(blockchainNetwork.blockchain) can't be remove")
            return
        }

        if amountType == .coin {
            removeBlockchain(blockchainNetwork)
        } else if case let .token(token) = amountType {
            removeToken(token, blockchainNetwork: blockchainNetwork)
        }
    }

    private func removeBlockchain(_ blockchainNetwork: BlockchainNetwork) {
        tokenItemsRepository.remove([blockchainNetwork])

        stateUpdateQueue.sync {
            if let walletModels = self.walletModels {
                state = .loaded(walletModel: walletModels.filter { $0.blockchainNetwork != blockchainNetwork })
            }
        }
    }

    private func removeToken(_ token: BlockchainSdk.Token, blockchainNetwork: BlockchainNetwork) {
        if let walletModel = walletModels?.first(where: { $0.blockchainNetwork == blockchainNetwork }) {
            let isRemoved = walletModel.removeToken(token, for: cardId)

            if isRemoved {
                stateUpdateQueue.sync {
                    if let walletModels = self.walletModels {
                        state = .loaded(walletModel: walletModels)
                    }
                }
            }
        }
    }

    private func tryMigrateTokens(completion: @escaping () -> Void) {
        if migrated {
            completion()
            return
        }

        migrated = true

        let items = tokenItemsRepository.getItems()
        let itemsWithCustomTokens = items.filter { item in
            return item.tokens.contains(where: { $0.isCustom })
        }

        if itemsWithCustomTokens.isEmpty {
            completion()
            return
        }

        let publishers = itemsWithCustomTokens.flatMap { item in
            item.tokens.filter { $0.isCustom }.map { token -> AnyPublisher<Bool, Never> in
                let requestModel = CoinsListRequestModel(
                    contractAddress: token.contractAddress,
                    networkIds: [item.blockchainNetwork.blockchain.networkId]
                )

                return tangemApiService
                    .loadCoins(requestModel: requestModel)
                    .replaceError(with: [])
                    .map { [unowned self] models -> Bool in
                        if let updatedTokem = models.first?.items.compactMap({ $0.token }).first {
                            self.tokenItemsRepository.append([updatedTokem], blockchainNetwork: item.blockchainNetwork)
                            return true
                        }
                        return false
                    }
                    .eraseToAnyPublisher()
            }
        }

        Publishers.MergeMany(publishers)
            .collect(publishers.count)
            .sink { [unowned self] migrationResults in
                if migrationResults.contains(true) {
                    self.state = .loaded(walletModel: makeAllWalletModels())
                }
                completion()
            }
            .store(in: &bag)
    }

    private func tryMigrateTokens() -> AnyPublisher<Void, Never> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.success(()))
                return
            }

            self.tryMigrateTokens {
                promise(.success(()))
            }
        }
        .eraseToAnyPublisher()
    }

    private func updateTotalBalanceTokenList() {
        guard let walletModels = self.walletModels else {
            self.totalSumBalanceViewModel.update(with: [])
            return
        }

        let tokenItemViewModels = walletModels.flatMap { $0.tokenItemViewModels }
        totalSumBalanceViewModel.beginUpdates()
        totalSumBalanceViewModel.update(with: tokenItemViewModels)
    }

    private func updateCardPinSettings() {
        cardPinSettings.isPin1Default = !cardInfo.card.isAccessCodeSet
        cardInfo.card.isPasscodeSet.map { self.cardPinSettings.isPin2Default = !$0 }
    }

    private func updateCurrentSecurityOption() {
        if !(cardPinSettings.isPin1Default ?? true) {
            self.currentSecurityOption = .accessCode
        } else if !(cardPinSettings.isPin2Default ?? true) {
            self.currentSecurityOption = .passCode
        }
        else {
            self.currentSecurityOption = .longTap
        }
    }

    private func bind() {
        signer.signPublisher.sink { [unowned self] card in
            self.cardInfo.card = CardDTO(card: card) // [REDACTED_TODO_COMMENT]
            self.config = UserWalletConfigFactory(cardInfo).makeConfig()
            self.warningsService.setupWarnings(for: config)
            self.saveUserWallet()
        }
        .store(in: &bag)

        $walletsBalanceState
            .receive(on: RunLoop.main)
            .sink { [unowned self] state in
                switch state {
                case .inProgress:
                    break
                case .loaded:
                    // Delay to hide skeleton
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self.updateTotalBalanceTokenList()
                    }
                }
            }
            .store(in: &bag)

        totalSumBalanceViewModel
            .$totalFiatValueString
            .sink { [unowned self] newValue in
                withAnimation(nil) {
                    let newTotalBalance = newValue.string
                    self.totalBalance = newTotalBalance.isEmpty ? nil : newTotalBalance
                }
            }
            .store(in: &bag)
    }

    private func loadCardImage() {
        imageLoaderPublisher
            .weakAssignAnimated(to: \.cardImage, on: self)
            .store(in: &bag)
    }

    private func saveUserWallet() {
        let userWallet = self.userWallet
        let _ = userWalletListService.save(userWallet)
    }
}

extension CardViewModel {
    enum State {
        case created
        case empty
        case loaded(walletModel: [WalletModel])

        var walletModels: [WalletModel]? {
            switch self {
            case .loaded(let models):
                return models
            default:
                return nil
            }
        }
        var canUpdate: Bool {
            switch self {
            case .loaded:
                return true
            default:
                return false
            }
        }
    }
}

extension CardViewModel {
    enum WalletsBalanceState {
        case inProgress
        case loaded
    }
}
