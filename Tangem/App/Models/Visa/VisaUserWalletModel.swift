//
//  VisaUserWalletModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemVisa
import TangemFoundation

class VisaUserWalletModel {
    @Injected(\.quotesRepository) private var quotesRepository: TokenQuotesRepository
    @Injected(\.keysManager) private var keysManager: KeysManager
    @Injected(\.apiListProvider) private var apiListProvider: APIListProvider
    @Injected(\.visaRefreshTokenRepository) private var visaRefreshTokenRepository: VisaRefreshTokenRepository

    var accountAddress: String { visaPaymentAccountInteractor?.accountAddress ?? .unknown }

    var walletDidChangePublisher: AnyPublisher<State, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var balancesPublisher: AnyPublisher<AppVisaBalances?, Never> {
        balancesSubject.eraseToAnyPublisher()
    }

    var limitsPublisher: AnyPublisher<AppVisaLimits?, Never> {
        cardSettingsSubject
            .map { cardSettings in
                guard let cardSettings else {
                    return nil
                }

                return AppVisaLimits(limits: cardSettings.limits)
            }
            .eraseToAnyPublisher()
    }

    var balances: AppVisaBalances? {
        balancesSubject.value
    }

    var limits: AppVisaLimits? {
        guard let cardSettings = cardSettingsSubject.value else {
            return nil
        }

        return .init(limits: cardSettings.limits)
    }

    var transactionHistoryStatePublisher: AnyPublisher<TransactionHistoryServiceState, Never> {
        transactionHistoryService?.statePublisher ?? Just(.failedToLoad(ModelError.authorizationError)).eraseToAnyPublisher()
    }

    var transactionHistoryItems: [TransactionListItem] {
        guard let transactionHistoryService else {
            return []
        }

        let historyMapper = VisaTransactionHistoryMapper(currencySymbol: currencySymbol)
        return historyMapper.mapTransactionListItem(from: transactionHistoryService.items)
    }

    var canFetchMoreTransactionHistory: Bool {
        transactionHistoryService?.canFetchMoreHistory ?? false
    }

    var currencySymbol: String {
        tokenItem?.currencySymbol ?? "Not loaded"
    }

    var tokenItem: TokenItem?

    private var cardId: String {
        cardInfo.card.cardId
    }

    private var cardInfoAuthorizationTokens: VisaAuthorizationTokens? {
        guard case .visa(let tokens) = cardInfo.walletData else {
            return nil
        }

        return tokens.authTokens
    }

    private var cardWalletAddress: String?
    private let userWalletModel: UserWalletModel
    private var cardInfo: CardInfo
    private var authorizationTokensHandler: VisaAuthorizationTokensHandler?
    private var transactionHistoryService: VisaTransactionHistoryService?
    private var visaPaymentAccountInteractor: VisaPaymentAccountInteractor?

    private let balancesSubject = CurrentValueSubject<AppVisaBalances?, Never>(nil)
    private let customerCardInfoSubject = CurrentValueSubject<VisaCustomerCardInfo?, Never>(nil)
    private let cardSettingsSubject = CurrentValueSubject<VisaPaymentAccountCardSettings?, Never>(nil)
    private let stateSubject = CurrentValueSubject<State, Never>(.notInitialized)
    private let refreshTokenNotificationSubject = CurrentValueSubject<NotificationViewInput?, Never>(nil)
    private let alertSubject = CurrentValueSubject<AlertBinder?, Never>(nil)
    private let logger = VisaLogger

    private var updateTask: Task<Void, Never>?
    private var historyReloadTask: Task<Void, Never>?

    init(userWalletModel: UserWalletModel, cardInfo: CardInfo) {
        self.userWalletModel = userWalletModel
        self.cardInfo = cardInfo

        let appUtilities = VisaAppUtilities()
        if let walletPublicKey = appUtilities.makeBlockchainKey(using: userWalletModel.keysRepository.keys) {
            cardWalletAddress = try? AddressServiceFactory(blockchain: appUtilities.blockchainNetwork.blockchain)
                .makeAddressService()
                .makeAddress(for: walletPublicKey, with: .default)
                .value
        }

        initialSetup()
    }

    func exploreURL() -> URL? {
        let linkProvider = ExternalLinkProviderFactory().makeProvider(for: VisaUtilities().visaBlockchain)
        return linkProvider.url(address: accountAddress, contractAddress: tokenItem?.token?.contractAddress)
    }

    func transaction(with id: UInt64) -> VisaTransactionRecord? {
        transactionHistoryService?.items.first(where: { $0.id == id })
    }

    func generalUpdateAsync() async {
        if visaPaymentAccountInteractor == nil {
            await setupPaymentAccountInteractorAsync()
            return
        }

        await withTaskGroup(of: Void.self) { [weak self] group in
            guard let self else { return }

            stateSubject.send(.loading)
            group.addTask {
                guard let currencyId = self.tokenItem?.currencyId else {
                    return
                }

                await self.quotesRepository.loadQuotes(currencyIds: [currencyId])
            }

            group.addTask { await self.loadBalancesAndLimits() }

            group.addTask { await self.reloadHistoryAsync() }

            await group.waitForAll()
            stateSubject.send(.idle)
        }
    }

    func reloadHistory() {
        guard historyReloadTask == nil else {
            return
        }

        historyReloadTask = Task { [weak self] in
            await self?.reloadHistoryAsync()
            self?.historyReloadTask = nil
        }
    }

    func loadNextHistoryPage() {
        guard historyReloadTask == nil else {
            return
        }

        historyReloadTask = Task { [weak self] in
            await self?.transactionHistoryService?.loadNextPage()
            self?.historyReloadTask = nil
        }
    }

    private func initialSetup() {
        Task { [weak self] in
            await self?.initialSetupAsync()
        }
    }

    private func initialSetupAsync() async {
        do {
            try await setupAuthorizationTokensHandler()
        } catch let modelError as ModelError {
            if modelError == .missingValidRefreshToken {
                showRefreshTokenExpiredNotification()
                return
            }
            stateSubject.send(.failedToInitialize(modelError))
            return
        } catch {
            logger.debug("Failed to setup authorization tokens handler. Proceeding to payment account interactor setup. Error: \(error)")
        }

        await setupPaymentAccountInteractorAsync()
    }

    private func setupPaymentAccountInteractorAsync() async {
        stateSubject.send(.loading)

        let visaUtilities = VisaUtilities()
        let blockchain = visaUtilities.visaBlockchain
        let factory = EVMSmartContractInteractorFactory(config: keysManager.blockchainConfig)

        let smartContractInteractor: EVMSmartContractInteractor
        do {
            let apiList = try await apiListProvider.apiListPublisher.async()
            smartContractInteractor = try factory.makeInteractor(for: blockchain, apiInfo: apiList[blockchain.networkId] ?? [])
        } catch {
            VisaLogger.error(self, "Failed to setup bridge", error: error)
            stateSubject.send(.failedToInitialize(.invalidBlockchain))
            return
        }

        guard let cardWalletAddress else {
            stateSubject.send(.failedToInitialize(.failedToGenerateAddress))
            return
        }

        do {
            let customerCardInfoProviderBuilder = VisaCustomerCardInfoProviderBuilder(
                isMockedAPIEnabled: await FeatureStorage.instance.isVisaAPIMocksEnabled,
                isTestnet: blockchain.isTestnet,
                cardId: cardId
            )
            let customerCardInfoProvider = customerCardInfoProviderBuilder.build(
                authorizationTokensHandler: authorizationTokensHandler,
                evmSmartContractInteractor: smartContractInteractor,
                urlSessionConfiguration: .defaultConfiguration
            )

            let customerCardInfo = try await customerCardInfoProvider.loadPaymentAccount(
                cardId: cardId,
                cardWalletAddress: cardWalletAddress
            )
            customerCardInfoSubject.send(customerCardInfo)

            let builder = await VisaPaymentAccountInteractorBuilder(
                isTestnet: blockchain.isTestnet,
                evmSmartContractInteractor: smartContractInteractor,
                urlSessionConfiguration: .defaultConfiguration,
                isMockedAPIEnabled: FeatureStorage.instance.isVisaAPIMocksEnabled
            )
            let interactor = try await builder.build(customerCardInfo: customerCardInfo)
            visaPaymentAccountInteractor = interactor
            tokenItem = .token(interactor.visaToken, .init(blockchain, derivationPath: nil))
            await generalUpdateAsync()
        } catch let error as VisaAuthorizationTokensHandlerError {
            if error == .refreshTokenExpired {
                showRefreshTokenExpiredNotification()
            } else {
                logger.debug("Authorization error. Error: \(error)")
                stateSubject.send(.failedToInitialize(.authorizationError))
            }
        } catch {
            VisaLogger.error(self, "Failed to create address from provided public key", error: error)
            stateSubject.send(.failedToInitialize(.failedToGenerateAddress))
        }
    }

    private func showRefreshTokenExpiredNotification() {
        stateSubject.send(.failedToInitialize(.missingValidRefreshToken))
    }

    private func updateBalanceAndLimits() {
        Task { [weak self] in
            await self?.loadBalancesAndLimits()
        }
    }

    private func loadBalancesAndLimits() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { [weak self] in await self?.updateBalances() }
            group.addTask { [weak self] in await self?.updateLimits() }

            await group.waitForAll()
        }
    }

    private func updateBalances() async {
        guard let visaPaymentAccountInteractor else {
            return
        }

        do {
            let balances = try await visaPaymentAccountInteractor.loadBalances()
            balancesSubject.send(.init(balances: balances))
        } catch {
            balancesSubject.send(nil)
        }
    }

    private func updateLimits() async {
        guard let visaPaymentAccountInteractor else {
            return
        }

        do {
            let cardSettings = try await visaPaymentAccountInteractor.loadCardSettings()
            cardSettingsSubject.send(cardSettings)
        } catch {
            logger.debug("Failed to load card settings. Error: \(error)")
            cardSettingsSubject.send(nil)
        }
    }

    private func reloadHistoryAsync() async {
        await transactionHistoryService?.reloadHistory()
    }
}

// MARK: - Authorization

extension VisaUserWalletModel {
    private func setupAuthorizationTokensHandler() async throws {
        guard let cardInfoAuthorizationTokens else {
            throw ModelError.invalidActivationState
        }

        let authorizationTokens: VisaAuthorizationTokens
        if let savedRefreshToken = visaRefreshTokenRepository.getToken(forCardId: cardId), savedRefreshToken != cardInfoAuthorizationTokens.refreshToken {
            authorizationTokens = .init(accessToken: nil, refreshToken: savedRefreshToken)
        } else {
            authorizationTokens = cardInfoAuthorizationTokens
        }

        try await setupTokensHandler(with: authorizationTokens)
    }

    private func setupTokensHandler(with tokens: VisaAuthorizationTokens) async throws {
        let authorizationTokensHandlerBuilder = await VisaAuthorizationTokensHandlerBuilder(isMockedAPIEnabled: FeatureStorage.instance.isVisaAPIMocksEnabled)
        let authorizationTokensHandler = authorizationTokensHandlerBuilder.build(
            cardId: cardId,
            cardActivationStatus: .activated(authTokens: tokens),
            refreshTokenSaver: self,
            urlSessionConfiguration: .defaultConfiguration
        )

        if await authorizationTokensHandler.refreshTokenExpired {
            throw ModelError.missingValidRefreshToken
        }

        if await authorizationTokensHandler.accessTokenExpired {
            try await authorizationTokensHandler.forceRefreshToken()
        }

        self.authorizationTokensHandler = authorizationTokensHandler
        setupTransactionHistoryService(with: authorizationTokensHandler)
    }

    func authorizeCard(completion: @escaping () -> Void) {
        let tangemSdk = TangemSdkDefaultFactory().makeTangemSdk()
        let handler = VisaCardScanHandler()

        tangemSdk.startSession(with: handler, cardId: cardId) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let activationState):
                guard let authTokens = activationState.authTokens else {
                    break
                }

                saveNewAuthorizationTokens(authTokens)
            case .failure(let sdkError):
                if sdkError.isUserCancelled {
                    break
                }

                alertSubject.send(sdkError.alertBinder)
            }

            completion()
            withExtendedLifetime(handler) {}
            withExtendedLifetime(tangemSdk) {}
        }
    }

    private func saveNewAuthorizationTokens(_ tokens: VisaAuthorizationTokens) {
        runTask(in: self, isDetached: false) { walletModel in
            try await walletModel.setupTokensHandler(with: tokens)
            await walletModel.setupPaymentAccountInteractorAsync()
        }
    }

    private func setupTransactionHistoryService(with authorizationTokensHandler: VisaAuthorizationTokensHandler) {
        let apiService = VisaAPIServiceBuilder().buildTransactionHistoryService(
            authorizationTokensHandler: authorizationTokensHandler,
            isTestnet: FeatureStorage.instance.isVisaTestnet,
            urlSessionConfiguration: .defaultConfiguration
        )
        transactionHistoryService = VisaTransactionHistoryService(apiService: apiService)
    }
}

extension VisaUserWalletModel: VisaRefreshTokenSaver {
    func saveRefreshTokenToStorage(refreshToken: String, cardId: String) throws {
        try visaRefreshTokenRepository.save(refreshToken: refreshToken, cardId: cardId)
    }
}

extension VisaUserWalletModel: VisaWalletMainHeaderSubtitleDataSource {
    var fiatBalance: String {
        BalanceFormatter().formatFiatBalance(fiatValue)
    }

    var blockchainName: String {
        "Polygon PoS"
    }

    private var fiatValue: Decimal? {
        guard
            let balanceValue = balancesSubject.value?.available,
            let currencyId = tokenItem?.currencyId
        else {
            return nil
        }

        let converter = BalanceConverter()
        return converter.convertToFiat(balanceValue, currencyId: currencyId)
    }
}

extension VisaUserWalletModel: MainHeaderBalanceProvider {
    var balance: LoadableTokenBalanceView.State {
        mapToLoadableTokenBalanceViewState(state: stateSubject.value, balances: balancesSubject.value)
    }

    var balancePublisher: AnyPublisher<LoadableTokenBalanceView.State, Never> {
        stateSubject
            .combineLatest(balancesSubject)
            .withWeakCaptureOf(self)
            .map { $0.mapToLoadableTokenBalanceViewState(state: $1.0, balances: $1.1) }
            .eraseToAnyPublisher()
    }

    private func mapToLoadableTokenBalanceViewState(state: State, balances: AppVisaBalances?) -> LoadableTokenBalanceView.State {
        switch state {
        case .notInitialized, .loading:
            return .loading()
        case .failedToInitialize:
            return .failed(cached: .string(BalanceFormatter.defaultEmptyBalanceString))
        case .idle:
            if let balances, let tokenItem {
                let balanceFormatter = BalanceFormatter()
                let formattedBalance = balanceFormatter.formatCryptoBalance(balances.available, currencyCode: tokenItem.currencySymbol)
                let formattedForMain = balanceFormatter.formatAttributedTotalBalance(fiatBalance: formattedBalance)
                return .loaded(text: .attributed(formattedForMain))
            } else {
                return .loading()
            }
        }
    }
}

extension VisaUserWalletModel: CustomStringConvertible {
    var description: String {
        objectDescription(self)
    }
}

extension VisaUserWalletModel {
    enum State: Hashable {
        case notInitialized
        case loading
        case failedToInitialize(ModelError)
        case idle
    }

    enum ModelError: Error, Hashable {
        case missingRequiredBlockchain
        case invalidBlockchain
        case noPaymentAccount
        case missingPublicKey
        case failedToGenerateAddress
        case authorizationError
        case missingValidRefreshToken
        case missingCardId
        case invalidConfig
        case invalidActivationState

        var notificationEvent: VisaNotificationEvent {
            switch self {
            case .missingRequiredBlockchain: return .missingRequiredBlockchain
            case .invalidBlockchain: return .notValidBlockchain
            case .noPaymentAccount: return .failedToLoadPaymentAccount
            case .missingPublicKey: return .missingPublicKey
            case .failedToGenerateAddress: return .failedToGenerateAddress
            case .authorizationError: return .authorizationError
            case .missingValidRefreshToken: return .missingValidRefreshToken
            case .missingCardId: return .missingCardId
            case .invalidConfig: return .invalidConfig
            case .invalidActivationState: return .invalidActivationState
            }
        }
    }
}

/// - Note: for now this model will proxy request to nested UserWalletModel
/// We need to refactor `CommonUserWalletModel` and `UserWalletConfig` creation
/// This is complex task, so it will be made later.
extension VisaUserWalletModel: UserWalletModel {
    var hasBackupCards: Bool { false }

    var config: any UserWalletConfig { userWalletModel.config }

    var userWalletId: UserWalletId { userWalletModel.userWalletId }

    var tangemApiAuthData: TangemApiTarget.AuthData { userWalletModel.tangemApiAuthData }

    var walletModelsManager: any WalletModelsManager { userWalletModel.walletModelsManager }

    var userTokensManager: any UserTokensManager { userWalletModel.userTokensManager }

    var userTokenListManager: any UserTokenListManager { userWalletModel.userTokenListManager }

    var keysRepository: any KeysRepository { userWalletModel.keysRepository }

    var signer: TangemSigner { userWalletModel.signer }

    var updatePublisher: AnyPublisher<Void, Never> { userWalletModel.updatePublisher }

    var backupInput: OnboardingInput? { nil }

    var cardImagePublisher: AnyPublisher<CardImageResult, Never> { userWalletModel.cardImagePublisher }

    var totalSignedHashes: Int { userWalletModel.totalSignedHashes }

    var name: String { userWalletModel.name }

    var cardHeaderImagePublisher: AnyPublisher<ImageType?, Never> { userWalletModel.cardHeaderImagePublisher }

    var userWalletNamePublisher: AnyPublisher<String, Never> { userWalletModel.userWalletNamePublisher }

    var totalBalance: TotalBalanceState { userWalletModel.totalBalance }

    var totalBalancePublisher: AnyPublisher<TotalBalanceState, Never> { userWalletModel.totalBalancePublisher }

    var cardsCount: Int { 1 }

    var hasImportedWallets: Bool { false }

    var analyticsContextData: AnalyticsContextData { userWalletModel.analyticsContextData }

    var isUserWalletLocked: Bool { false }

    var isTokensListEmpty: Bool { userWalletModel.isTokensListEmpty }

    var emailData: [EmailCollectedData] { userWalletModel.emailData }

    var emailConfig: EmailConfig? { userWalletModel.emailConfig }

    var wcWalletModelProvider: any WalletConnectWalletModelProvider { NotSupportedWalletConnectWalletModelProvider() }

    var keysDerivingInteractor: any KeysDeriving { userWalletModel.keysDerivingInteractor }

    func validate() -> Bool { userWalletModel.validate() }

    func onBackupUpdate(type: BackupUpdateType) {}

    func updateWalletName(_ name: String) {
        userWalletModel.updateWalletName(name)
    }

    func addAssociatedCard(_ cardId: String) {}
}

extension VisaUserWalletModel: UserWalletSerializable {
    func serialize() -> StoredUserWallet {
        let name = name.isEmpty ? config.cardName : name

        let newStoredUserWallet = StoredUserWallet(
            userWalletId: userWalletId.value,
            name: name,
            card: cardInfo.card,
            associatedCardIds: [],
            walletData: cardInfo.walletData,
            artwork: cardInfo.artwork.artworkInfo
        )

        return newStoredUserWallet
    }
}
