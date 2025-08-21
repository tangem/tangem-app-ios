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
import TangemAssets
import TangemVisa
import TangemFoundation
import TangemNFT
import struct TangemUIUtils.AlertBinder

/// Model responsible for interacting with payment account and BFF
/// Main setup logic is in `setupPaymentAccountInteractorAsync` . It setups payment account interactor which is responsible with blockchain requests
/// It can't be setup on initialization, because we need to get authorization tokens to be able to request address from BFF
/// After receiving tokens we can request customer information and get payment account address and start loading balances and limits info
/// At first iteration we didn't store payment account information in the app, this might change later.
/// Transaction history also requested from BFF, so it can be loaded while authorization tokens didn't retrieved
/// If refresh token for this Visa card is staled we need to request a new one through signing authorization request using card wallet.
final class VisaUserWalletModel {
    let dataProvider: VisaDataProvider
    let userWalletModel: UserWalletModel
    private var cardInfo: CardInfo

    init(userWalletModel: UserWalletModel, cardInfo: CardInfo) {
        self.userWalletModel = userWalletModel
        self.cardInfo = cardInfo

        dataProvider = TangemPayDataProvider(
            cardWalletAddress: VisaUtilities.makeAddress(using: userWalletModel.keysRepository.keys)?.value,
            cardId: cardInfo.card.cardId,
            authorizationTokensProvider: VisaAuthorizationTokensProvider(cardInfo: cardInfo),
            name: userWalletModel.name,
            walletHeaderImagePublisher: userWalletModel.walletHeaderImagePublisher,
            updatePublisher: userWalletModel.updatePublisher
        )
    }

    func getDisabledLocalizedReason(for feature: UserWalletFeature) -> String? {
        config.getDisabledLocalizedReason(for: feature)
    }
}

extension VisaUserWalletModel {
    enum State: Hashable {
        case notInitialized
        case loading
        case failedToLoad(ModelError)
        case idle
    }

    enum ModelError: Hashable {
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
            case .missingValidRefreshToken: return .missingValidRefreshToken
            default: return .error(self)
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

    var tangemApiAuthData: TangemApiAuthorizationData? { userWalletModel.tangemApiAuthData }

    var walletModelsManager: any WalletModelsManager { userWalletModel.walletModelsManager }

    var userTokensManager: any UserTokensManager { userWalletModel.userTokensManager }

    var userTokenListManager: any UserTokenListManager { userWalletModel.userTokenListManager }

    var nftManager: any NFTManager { NotSupportedNFTManager() }

    var keysRepository: any KeysRepository { userWalletModel.keysRepository }

    var signer: TangemSigner { userWalletModel.signer }

    var updatePublisher: AnyPublisher<UpdateResult, Never> { userWalletModel.updatePublisher }

    var backupInput: OnboardingInput? { nil }

    var walletImageProvider: WalletImageProviding { userWalletModel.walletImageProvider }

    var name: String { userWalletModel.name }

    var walletHeaderImagePublisher: AnyPublisher<ImageType?, Never> { userWalletModel.walletHeaderImagePublisher }

    var totalBalance: TotalBalanceState { userWalletModel.totalBalance }

    var totalBalancePublisher: AnyPublisher<TotalBalanceState, Never> { userWalletModel.totalBalancePublisher }

    var cardSetLabel: String { config.cardSetLabel }

    var hasImportedWallets: Bool { false }

    var analyticsContextData: AnalyticsContextData { userWalletModel.analyticsContextData }

    var isUserWalletLocked: Bool { false }

    var isTokensListEmpty: Bool { userWalletModel.isTokensListEmpty }

    var emailData: [EmailCollectedData] { userWalletModel.emailData }

    var emailConfig: EmailConfig? { userWalletModel.emailConfig }

    var wcWalletModelProvider: any WalletConnectWalletModelProvider { NotSupportedWalletConnectWalletModelProvider() }

    var refcodeProvider: RefcodeProvider? { userWalletModel.refcodeProvider }

    var keysDerivingInteractor: any KeysDeriving { userWalletModel.keysDerivingInteractor }

    var userTokensPushNotificationsManager: any UserTokensPushNotificationsManager {
        userWalletModel.userTokensPushNotificationsManager
    }

    var accountModelsManager: AccountModelsManager {
        userWalletModel.accountModelsManager
    }

    func validate() -> Bool { userWalletModel.validate() }

    func update(type: UpdateRequest) {
        userWalletModel.update(type: type)
    }

    func addAssociatedCard(cardId: String) {}
}

extension VisaUserWalletModel: UserWalletSerializable {
    func serializePublic() -> StoredUserWallet {
        let name = name.isEmpty ? config.defaultName : name

        var mutableCardInfo = cardInfo
        mutableCardInfo.card.wallets = []

        let newStoredUserWallet = StoredUserWallet(
            userWalletId: userWalletId.value,
            name: name,
            walletInfo: .cardWallet(mutableCardInfo)
        )

        return newStoredUserWallet
    }

    func serializePrivate() -> StoredUserWallet.SensitiveInfo {
        return .cardWallet(keys: cardInfo.card.wallets)
    }
}

extension VisaUserWalletModel: AssociatedCardIdsProvider {
    var associatedCardIds: Set<String> {
        cardInfo.associatedCardIds
    }
}

final class TangemPayDataProvider {
    private(set) var tokenItem: TokenItem?

    @Injected(\.quotesRepository) private var quotesRepository: TokenQuotesRepository
    @Injected(\.keysManager) private var keysManager: KeysManager
    @Injected(\.apiListProvider) private var apiListProvider: APIListProvider
    @Injected(\.visaRefreshTokenRepository) private var visaRefreshTokenRepository: VisaRefreshTokenRepository

    let name: String
    let walletHeaderImagePublisher: AnyPublisher<ImageType?, Never>
    let updatePublisher: AnyPublisher<UpdateResult, Never>

    // [REDACTED_TODO_COMMENT]
    private let cardWalletAddress: String?
    private let transactionHistoryService: VisaTransactionHistoryService
    private let authorizationTokensProvider: AuthorizationTokensProvider

    private var authorizationTokensHandler: VisaAuthorizationTokensHandler?
    private var visaPaymentAccountInteractor: VisaPaymentAccountInteractor?

    private let stateSubject = CurrentValueSubject<VisaUserWalletModel.State, Never>(.notInitialized)
    private let balancesSubject = CurrentValueSubject<AppVisaBalances?, Never>(nil)
    private let cardSettingsSubject = CurrentValueSubject<VisaPaymentAccountCardSettings?, Never>(nil)

    private var historyReloadTask: Task<Void, Never>?

    private var currencySymbol: String {
        tokenItem?.currencySymbol ?? "Not loaded"
    }

    init(
        cardWalletAddress: String?,
        cardId: String?,
        authorizationTokensProvider: AuthorizationTokensProvider,
        name: String,
        walletHeaderImagePublisher: AnyPublisher<ImageType?, Never>,
        updatePublisher: AnyPublisher<UpdateResult, Never>
    ) {
        self.cardWalletAddress = cardWalletAddress
        transactionHistoryService = .init(cardId: cardId)
        self.authorizationTokensProvider = authorizationTokensProvider

        self.name = name
        self.walletHeaderImagePublisher = walletHeaderImagePublisher
        self.updatePublisher = updatePublisher

        Task { [weak self] in
            await self?.initialSetupAsync()
        }
    }

    private func initialSetupAsync() async {
        do {
            let tokens = try await authorizationTokensProvider.makeAuthTokensFromRefreshRepository()
            authorizationTokensHandler = try await authorizationTokensProvider.makeTokensHandler(with: tokens)
            try await setupPaymentAccountInteractorAsync()
        } catch let modelError as VisaUserWalletModel.ModelError {
            stateSubject.send(.failedToLoad(modelError))
        } catch {
            VisaLogger.error("Failed to setup authorization tokens handler. Proceeding to payment account interactor setup.", error: error)
        }
    }

    private func setupPaymentAccountInteractorAsync() async throws(VisaUserWalletModel.ModelError) {
        stateSubject.send(.loading)

        let blockchain = VisaUtilities.visaBlockchain
        let factory = EVMSmartContractInteractorFactory(blockchainSdkKeysConfig: keysManager.blockchainSdkKeysConfig, tangemProviderConfig: .ephemeralConfiguration)

        let smartContractInteractor: EVMSmartContractInteractor
        do {
            let apiList = try await apiListProvider.apiListPublisher.async()
            smartContractInteractor = try factory.makeInteractor(for: blockchain, apiInfo: apiList[blockchain.networkId] ?? [])
        } catch {
            VisaLogger.error("Failed to setup bridge", error: error)
            throw .invalidBlockchain
        }

        guard let cardWalletAddress else {
            throw .failedToGenerateAddress
        }

        do {
            let customerCardInfoProvider = VisaCustomerCardInfoProviderBuilder()
                .build(
                    authorizationTokensHandler: authorizationTokensHandler,
                    evmSmartContractInteractor: smartContractInteractor
                )

            let customerCardInfo = try await customerCardInfoProvider.loadPaymentAccount(
                cardWalletAddress: cardWalletAddress
            )

            await transactionHistoryService.reloadHistory()
            let interactor = try await VisaPaymentAccountInteractorBuilder(evmSmartContractInteractor: smartContractInteractor)
                .build(customerCardInfo: customerCardInfo)

            visaPaymentAccountInteractor = interactor

            tokenItem = .token(interactor.visaToken, .init(blockchain, derivationPath: nil))
            if let authorizationTokensHandler,
               let customerInfo = customerCardInfo.customerInfo {
                let apiService = VisaAPIServiceBuilder()
                    .buildTransactionHistoryService(authorizationTokensHandler: authorizationTokensHandler)

                transactionHistoryService.setupApiService(productInstanceId: customerInfo.productInstance.id, apiService: apiService)
            }
            await generalUpdateAsync()
        } catch let error as VisaAuthorizationTokensHandlerError {
            if error == .refreshTokenExpired {
                throw .missingValidRefreshToken
            } else {
                VisaLogger.error("Authorization error", error: error)
                throw .authorizationError
            }
        } catch {
            VisaLogger.error("Failed to create address from provided public key", error: error)
            throw .failedToGenerateAddress
        }
    }

    func generalUpdateAsync() async {
        guard let visaPaymentAccountInteractor else {
            do {
                try await setupPaymentAccountInteractorAsync()
            } catch {
                stateSubject.send(.failedToLoad(error))
            }
            return
        }

        await withTaskGroup(of: Void.self) { [weak self] group in
            guard let self else { return }

            if let currencyId = tokenItem?.currencyId {
                group.addTask { await self.quotesRepository.loadQuotes(currencyIds: [currencyId]) }
            }

            group.addTask {
                let balances = try? await visaPaymentAccountInteractor.loadBalances()
                self.balancesSubject.send(balances.map(AppVisaBalances.init))
            }

            group.addTask {
                let cardSettings = try? await visaPaymentAccountInteractor.loadCardSettings()
                self.cardSettingsSubject.send(cardSettings)
            }

            group.addTask {
                await self.transactionHistoryService.reloadHistory()
            }

            await group.waitForAll()
            stateSubject.send(.idle)
        }
    }
}

protocol VisaDataProvider: MainHeaderBalanceProvider, VisaWalletMainHeaderSubtitleDataSource, MainHeaderSupplementInfoProvider {
    var tokenItem: TokenItem? { get }
    var balances: AppVisaBalances? { get }
    var emailConfig: EmailConfig? { get }
    var canFetchMoreTransactionHistory: Bool { get }
    var transactionHistoryItems: [TransactionListItem] { get }
    var accountAddress: String? { get }
    var currentModelState: VisaUserWalletModel.State { get }
    var limits: AppVisaLimits? { get }

    var walletDidChangePublisher: AnyPublisher<VisaUserWalletModel.State, Never> { get }
    var transactionHistoryStatePublisher: AnyPublisher<TransactionHistoryServiceState, Never> { get }

    func transaction(with id: UInt64) -> VisaTransactionRecord?
    func exploreURL() -> URL?
    func reloadHistory()
    func loadNextHistoryPage()
    func authorizeCard(completion: @escaping () -> Void)

    func generalUpdateAsync() async

    func getDisabledLocalizedReason(for feature: UserWalletFeature) -> String?
}

extension TangemPayDataProvider: VisaDataProvider {
    var balances: AppVisaBalances? {
        balancesSubject.value
    }

    var emailConfig: EmailConfig? {
        .init(recipient: "recipient", subject: "subject")
    }

    var canFetchMoreTransactionHistory: Bool {
        transactionHistoryService.canFetchMoreHistory
    }

    var transactionHistoryItems: [TransactionListItem] {
        VisaTransactionHistoryMapper(currencySymbol: currencySymbol)
            .mapTransactionListItem(from: transactionHistoryService.items)
    }

    var accountAddress: String? {
        visaPaymentAccountInteractor?.accountAddress
    }

    var currentModelState: VisaUserWalletModel.State {
        stateSubject.value
    }

    var limits: AppVisaLimits? {
        guard let cardSettings = cardSettingsSubject.value else {
            return nil
        }

        return .init(limits: cardSettings.limits)
    }

    var walletDidChangePublisher: AnyPublisher<VisaUserWalletModel.State, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var transactionHistoryStatePublisher: AnyPublisher<TransactionHistoryServiceState, Never> {
        transactionHistoryService.statePublisher
    }

    func transaction(with id: UInt64) -> TangemVisa.VisaTransactionRecord? {
        transactionHistoryService.items.first(where: { $0.id == id })
    }

    func exploreURL() -> URL? {
        guard let accountAddress else {
            return nil
        }

        let visaBlockchain = VisaUtilities.visaBlockchain
        let linkProvider = ExternalLinkProviderFactory().makeProvider(for: visaBlockchain)
        return linkProvider.url(address: accountAddress, contractAddress: tokenItem?.token?.contractAddress)
    }

    func reloadHistory() {
        guard historyReloadTask == nil else {
            return
        }

        historyReloadTask = Task { [weak self] in
            await self?.transactionHistoryService.reloadHistory()
            self?.historyReloadTask = nil
        }
    }

    func loadNextHistoryPage() {
        guard historyReloadTask == nil else {
            return
        }

        historyReloadTask = Task { [weak self] in
            await self?.transactionHistoryService.loadNextPage()
            self?.historyReloadTask = nil
        }
    }

    func authorizeCard(completion: @escaping () -> Void) {
        runTask(in: self, isDetached: false) { walletModel in
            if let tokens = await walletModel.authorizationTokensProvider.getSavedTokens() {
                walletModel.authorizationTokensHandler = try? await walletModel.authorizationTokensProvider.makeTokensHandler(with: tokens)

                do {
                    try await walletModel.setupPaymentAccountInteractorAsync()
                } catch let error as VisaUserWalletModel.ModelError {
                    walletModel.stateSubject.send(.failedToLoad(error))
                } catch {
                    walletModel.stateSubject.send(.failedToLoad(.failedToGenerateAddress))
                }
            }
            completion()
        }
    }

    func getDisabledLocalizedReason(for feature: UserWalletFeature) -> String? {
        // [REDACTED_TODO_COMMENT]
        nil
    }
}

// MARK: MainHeaderBalanceProvider

extension TangemPayDataProvider {
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

    private func mapToLoadableTokenBalanceViewState(
        state: VisaUserWalletModel.State,
        balances: AppVisaBalances?
    ) -> LoadableTokenBalanceView.State {
        switch state {
        case .notInitialized, .loading:
            return .loading()
        case .failedToLoad:
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

// MARK: VisaWalletMainHeaderSubtitleDataSource

extension TangemPayDataProvider {
    var fiatBalance: String {
        BalanceFormatter().formatFiatBalance(fiatValue)
    }

    var blockchainName: String {
        VisaUtilities.visaBlockchain.displayName
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

enum AuthorizationTokensProviderError: Error {
    case invalid
}

protocol AuthorizationTokensProvider {
    func makeAuthTokensFromRefreshRepository() async throws -> VisaAuthorizationTokens
    func getSavedTokens() async -> VisaAuthorizationTokens?
    func makeTokensHandler(with tokens: VisaAuthorizationTokens) async throws -> VisaAuthorizationTokensHandler?
}

final class TangemPayAuthorizationTokensProvider: AuthorizationTokensProvider {
    private let walletModel: any WalletModel

    init(walletModel: any WalletModel) {
        self.walletModel = walletModel
    }

    func makeAuthTokensFromRefreshRepository() async throws -> VisaAuthorizationTokens {
        // [REDACTED_TODO_COMMENT]
        throw AuthorizationTokensProviderError.invalid
    }

    func getSavedTokens() async -> VisaAuthorizationTokens? {
        let account = VisaAccount(walletModel: walletModel)
        return try? await account.getTokens()
    }

    func makeTokensHandler(with tokens: VisaAuthorizationTokens) async throws -> (any VisaAuthorizationTokensHandler)? {
        VisaAuthorizationTokensHandlerBuilder()
            .build(visaAuthorizationTokens: tokens)
    }

    func getTokensHandler() async throws -> (any VisaAuthorizationTokensHandler)? {
        let account = VisaAccount(walletModel: walletModel)
        let tokens = try await account.getTokens()
        return VisaAuthorizationTokensHandlerBuilder()
            .build(visaAuthorizationTokens: tokens)
    }
}

final class VisaAuthorizationTokensProvider: AuthorizationTokensProvider, VisaRefreshTokenSaver {
    @Injected(\.visaRefreshTokenRepository) private var visaRefreshTokenRepository: VisaRefreshTokenRepository
    private let cardInfo: CardInfo

    private var cardId: String {
        cardInfo.card.cardId
    }

    private var cardInfoAuthorizationTokens: VisaAuthorizationTokens? {
        guard case .visa(let tokens) = cardInfo.walletData else {
            return nil
        }

        return tokens.authTokens
    }

    init(cardInfo: CardInfo) {
        self.cardInfo = cardInfo
    }

    func makeAuthTokensFromRefreshRepository() async throws -> VisaAuthorizationTokens {
        guard let cardInfoAuthorizationTokens else {
            throw VisaUserWalletModel.ModelError.invalidActivationState
        }

        if let savedRefreshToken = visaRefreshTokenRepository.getToken(forCardId: cardId), savedRefreshToken != cardInfoAuthorizationTokens.refreshToken {
            return .init(accessToken: nil, refreshToken: savedRefreshToken, authorizationType: .cardWallet)
        } else {
            return cardInfoAuthorizationTokens
        }
    }

    func getSavedTokens() async -> VisaAuthorizationTokens? {
        let tangemSdk = TangemSdkDefaultFactory().makeTangemSdk()
        let handler = VisaCardScanHandlerBuilder()
            .build(refreshTokenRepository: visaRefreshTokenRepository)

        return await withCheckedContinuation { continuation in
            tangemSdk.startSession(with: handler, cardId: cardId) { result in
                switch result {
                case .success(let activationState):
                    continuation.resume(returning: activationState.authTokens)
                case .failure:
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    func makeTokensHandler(with tokens: VisaAuthorizationTokens) async throws -> VisaAuthorizationTokensHandler? {
        guard tokens.authorizationType == .cardWallet else {
            VisaLogger.info("Saved authorization tokens in VisaUserWalletModel is not for activated card. Skip tokens handler setup")
            return nil
        }

        let authorizationTokensHandler = VisaAuthorizationTokensHandlerBuilder()
            .build(
                cardId: cardId,
                cardActivationStatus: .activated(authTokens: tokens),
                refreshTokenSaver: self
            )

        if await authorizationTokensHandler.refreshTokenExpired {
            throw VisaUserWalletModel.ModelError.missingValidRefreshToken
        }

        if await authorizationTokensHandler.accessTokenExpired {
            try await authorizationTokensHandler.forceRefreshToken()
        }

        return authorizationTokensHandler
    }

    func saveRefreshTokenToStorage(refreshToken: String, cardId: String) throws {
        try visaRefreshTokenRepository.save(refreshToken: refreshToken, cardId: cardId)
    }
}
