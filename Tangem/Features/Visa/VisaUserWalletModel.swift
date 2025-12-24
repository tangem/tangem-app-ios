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
    @Injected(\.quotesRepository) private var quotesRepository: TokenQuotesRepository
    @Injected(\.keysManager) private var keysManager: KeysManager
    @Injected(\.apiListProvider) private var apiListProvider: APIListProvider
    @Injected(\.visaRefreshTokenRepository) private var visaRefreshTokenRepository: VisaRefreshTokenRepository

    var accountAddress: String? { visaPaymentAccountInteractor?.accountAddress }

    var walletDidChangePublisher: AnyPublisher<State, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var currentModelState: State {
        stateSubject.value
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
        // Transaction history api changed during Visa 2.0 phase.
        // Making this functionality work for Visa 1.0 would require new implementation
        .empty
    }

    var transactionHistoryItems: [TransactionListItem] {
        // Transaction history api changed during Visa 2.0 phase.
        // Making this functionality work for Visa 1.0 would require new implementation
        []
    }

    var canFetchMoreTransactionHistory: Bool {
        // Transaction history api changed during Visa 2.0 phase.
        // Making this functionality work for Visa 1.0 would require new implementation
        false
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

    let userWalletModel: UserWalletModel
    private var cardWalletAddress: String?
    private var cardInfo: CardInfo
    private var authorizationTokensHandler: VisaAuthorizationTokensHandler?
    private var visaPaymentAccountInteractor: VisaPaymentAccountInteractor?

    private let balancesSubject = CurrentValueSubject<AppVisaBalances?, Never>(nil)
    private let customerCardInfoSubject = CurrentValueSubject<VisaCustomerCardInfo?, Never>(nil)
    private let cardSettingsSubject = CurrentValueSubject<VisaPaymentAccountCardSettings?, Never>(nil)
    private let stateSubject = CurrentValueSubject<State, Never>(.notInitialized)
    private let alertSubject = CurrentValueSubject<AlertBinder?, Never>(nil)

    private var historyReloadTask: Task<Void, Never>?

    init(userWalletModel: UserWalletModel, cardInfo: CardInfo) {
        self.userWalletModel = userWalletModel
        self.cardInfo = cardInfo

        let cardWalletAddress = VisaUtilities.makeAddress(using: userWalletModel.keysRepository.keys)?.value
        self.cardWalletAddress = cardWalletAddress

        initialSetup()
    }

    func exploreURL() -> URL? {
        guard let accountAddress else {
            return nil
        }

        let visaBlockchain = VisaUtilities.visaBlockchain
        let linkProvider = ExternalLinkProviderFactory().makeProvider(for: visaBlockchain)
        return linkProvider.url(address: accountAddress, contractAddress: tokenItem?.token?.contractAddress)
    }

    func transaction(with id: UInt64) -> VisaTransactionRecord? {
        // Transaction history api changed during Visa 2.0 phase.
        // Making this functionality work for Visa 1.0 would require new implementation
        nil
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
        // Transaction history api changed during Visa 2.0 phase.
        // Making this functionality work for Visa 1.0 would require new implementation
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
            stateSubject.send(.failedToLoad(modelError))
            return
        } catch {
            VisaLogger.error("Failed to setup authorization tokens handler. Proceeding to payment account interactor setup.", error: error)
        }

        await setupPaymentAccountInteractorAsync()
    }

    private func setupPaymentAccountInteractorAsync() async {
        stateSubject.send(.loading)

        let blockchain = VisaUtilities.visaBlockchain
        let factory = EVMSmartContractInteractorFactory(blockchainSdkKeysConfig: keysManager.blockchainSdkKeysConfig, tangemProviderConfig: .ephemeralConfiguration)

        let smartContractInteractor: EVMSmartContractInteractor
        do {
            let apiList = try await apiListProvider.apiListPublisher.async()
            smartContractInteractor = try factory.makeInteractor(for: blockchain, apiInfo: apiList[blockchain.networkId] ?? [])
        } catch {
            VisaLogger.error("Failed to setup bridge", error: error)
            stateSubject.send(.failedToLoad(.invalidBlockchain))
            return
        }

        guard let cardWalletAddress else {
            stateSubject.send(.failedToLoad(.failedToGenerateAddress))
            return
        }

        do {
            let customerCardInfoProvider = VisaCustomerCardInfoProviderBuilder()
                .build(
                    authorizationTokensHandler: authorizationTokensHandler,
                    evmSmartContractInteractor: smartContractInteractor
                )

            let customerCardInfo = try await customerCardInfoProvider.loadPaymentAccount(
                cardId: cardId,
                cardWalletAddress: cardWalletAddress
            )
            customerCardInfoSubject.send(customerCardInfo)

            await reloadHistoryAsync()
            let interactor = try await VisaPaymentAccountInteractorBuilder(evmSmartContractInteractor: smartContractInteractor)
                .build(customerCardInfo: customerCardInfo)

            visaPaymentAccountInteractor = interactor

            tokenItem = .token(interactor.visaToken, .init(blockchain, derivationPath: nil))
            if let authorizationTokensHandler,
               let customerInfo = customerCardInfo.customerInfo,
               let productInstance = customerInfo.productInstance {
                setupTransactionHistoryService(
                    productInstanceId: productInstance.id,
                    authorizationTokensHandler: authorizationTokensHandler
                )
            }
            await generalUpdateAsync()
        } catch let error as VisaAuthorizationTokensHandlerError {
            if error == .refreshTokenExpired {
                showRefreshTokenExpiredNotification()
            } else {
                VisaLogger.error("Authorization error", error: error)
                stateSubject.send(.failedToLoad(.authorizationError))
            }
        } catch {
            VisaLogger.error("Failed to create address from provided public key", error: error)
            stateSubject.send(.failedToLoad(.failedToGenerateAddress))
        }
    }

    private func showRefreshTokenExpiredNotification() {
        stateSubject.send(.failedToLoad(.missingValidRefreshToken))
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
            VisaLogger.error("Failed to load card settings", error: error)
            cardSettingsSubject.send(nil)
        }
    }

    private func reloadHistoryAsync() async {
        // Transaction history api changed during Visa 2.0 phase.
        // Making this functionality work for Visa 1.0 would require new implementation
    }
}

// MARK: - Authorization

extension VisaUserWalletModel {
    private func setupAuthorizationTokensHandler() async throws {
        guard let cardInfoAuthorizationTokens else {
            throw ModelError.invalidActivationState
        }

        let authorizationTokens: VisaAuthorizationTokens
        if let savedRefreshToken = visaRefreshTokenRepository.getToken(forVisaRefreshTokenId: .cardId(cardId)), savedRefreshToken != cardInfoAuthorizationTokens.refreshToken {
            authorizationTokens = .init(accessToken: nil, refreshToken: savedRefreshToken, authorizationType: .cardWallet)
        } else {
            authorizationTokens = cardInfoAuthorizationTokens
        }

        try await setupTokensHandler(with: authorizationTokens)
    }

    private func setupTokensHandler(with tokens: VisaAuthorizationTokens) async throws {
        guard tokens.authorizationType == .cardWallet else {
            VisaLogger.info("Saved authorization tokens in VisaUserWalletModel is not for activated card. Skip tokens handler setup")
            return
        }

        let authorizationTokensHandler = VisaAuthorizationTokensHandlerBuilder()
            .build(
                cardId: cardId,
                cardActivationStatus: .activated(authTokens: tokens),
                refreshTokenSaver: self,
                allowRefresherTask: true
            )

        if authorizationTokensHandler.refreshTokenExpired {
            throw ModelError.missingValidRefreshToken
        }

        if authorizationTokensHandler.accessTokenExpired {
            try await authorizationTokensHandler.forceRefreshToken()
        }

        self.authorizationTokensHandler = authorizationTokensHandler
    }

    func authorizeCard(completion: @escaping () -> Void) {
        let tangemSdk = TangemSdkDefaultFactory().makeTangemSdk()
        let handler = VisaCardScanHandlerBuilder()
            .build(refreshTokenRepository: visaRefreshTokenRepository)

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

    private func setupTransactionHistoryService(
        productInstanceId: String,
        authorizationTokensHandler: VisaAuthorizationTokensHandler
    ) {
        // Transaction history api changed during Visa 2.0 phase.
        // Making this functionality work for Visa 1.0 would require new implementation
    }
}

extension VisaUserWalletModel: VisaRefreshTokenSaver {
    func saveRefreshTokenToStorage(refreshToken: String, visaRefreshTokenId: VisaRefreshTokenId) throws {
        try visaRefreshTokenRepository.save(refreshToken: refreshToken, visaRefreshTokenId: visaRefreshTokenId)
    }
}

extension VisaUserWalletModel: VisaWalletMainHeaderSubtitleDataSource {
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

    // [REDACTED_TODO_COMMENT]
    var walletModelsManager: any WalletModelsManager { userWalletModel.walletModelsManager }

    // [REDACTED_TODO_COMMENT]
    var userTokensManager: any UserTokensManager { userWalletModel.userTokensManager }

    var nftManager: any NFTManager { NotSupportedNFTManager() }

    var keysRepository: any KeysRepository { userWalletModel.keysRepository }

    // [REDACTED_TODO_COMMENT]
    // [REDACTED_INFO]
    var paeraCustomer: PaeraCustomer? { nil }
    var paeraCustomerPublisher: AnyPublisher<PaeraCustomer?, Never> { .empty }

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

    var emailData: [EmailCollectedData] { userWalletModel.emailData }

    var emailConfig: EmailConfig? { userWalletModel.emailConfig }

    var wcWalletModelProvider: any WalletConnectWalletModelProvider { NotSupportedWalletConnectWalletModelProvider() }

    var wcAccountsWalletModelProvider: any WalletConnectAccountsWalletModelProvider {
        NotSupportedWalletConnectAccountsWalletModelProvider()
    }

    var refcodeProvider: RefcodeProvider? { userWalletModel.refcodeProvider }

    var keysDerivingInteractor: any KeysDeriving { userWalletModel.keysDerivingInteractor }

    var tangemPayAuthorizingInteractor: TangemPayAuthorizing {
        userWalletModel.tangemPayAuthorizingInteractor
    }

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
