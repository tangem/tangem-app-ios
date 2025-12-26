//
//  TangemPayAccount.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Combine
import Foundation
import TangemVisa
import TangemSdk
import TangemFoundation
import TangemAssets
import TangemLocalization

final class TangemPayAccount {
    var tangemPayStatusPublisher: AnyPublisher<TangemPayStatus, Never> {
        customerInfoSubject
            .map(\.tangemPayStatus)
            .eraseToAnyPublisher()
    }

    var tangemPayCard: VisaCustomerInfoResponse.Card? {
        mapToCard(visaCustomerInfoResponse: customerInfoSubject.value)
    }

    var tangemPayCardPublisher: AnyPublisher<VisaCustomerInfoResponse.Card?, Never> {
        customerInfoSubject
            .withWeakCaptureOf(self)
            .map { $0.mapToCard(visaCustomerInfoResponse: $1) }
            .eraseToAnyPublisher()
    }

    // MARK: - Withdraw

    lazy var tangemPayExpressCEXTransactionProcessor = TangemPayExpressCEXTransactionProcessor(
        withdrawTransactionService: withdrawTransactionService,
        walletPublicKey: TangemPayUtilities.getKey(from: keysRepository)
    )

    lazy var withdrawAvailabilityProvider: TangemPayWithdrawAvailabilityProvider = .init(
        withdrawTransactionService: withdrawTransactionService,
        tokenBalanceProvider: balancesService.availableBalanceProvider
    )

    // MARK: - Balances

    lazy var tangemPayMainHeaderBalanceProvider: MainHeaderBalanceProvider = TangemPayMainHeaderBalanceProvider(
        tangemPayTokenBalanceProvider: balancesProvider.fixedFiatTotalTokenBalanceProvider
    )

    var balancesProvider: TangemPayBalancesProvider { balancesService }

    let customerWalletAddress: String
    let customerInfoManagementService: any CustomerInfoManagementService
    let withdrawTransactionService: any TangemPayWithdrawTransactionService

    var depositAddress: String? {
        customerInfoSubject.value.depositAddress
    }

    var cardId: String? {
        customerInfoSubject.value.productInstance?.cardId
    }

    var isPinSet: Bool {
        customerInfoSubject.value.card?.isPinSet ?? false
    }

    let customerWalletId: String

    var cardNumberEnd: String? {
        customerInfoSubject.value.card?.cardNumberEnd
    }

    private let keysRepository: KeysRepository
    private let authorizationTokensHandler: TangemPayAuthorizationTokensHandler
    private let balancesService: any TangemPayBalancesService

    private let customerInfoSubject: CurrentValueSubject<VisaCustomerInfoResponse, Never>

    private let freezeUnfreezeOrderStatusPollingService: TangemPayOrderStatusPollingService

    init(
        customerWalletId: String,
        customerWalletAddress: String,
        customerInfo: VisaCustomerInfoResponse,
        keysRepository: KeysRepository,
        authorizationTokensHandler: TangemPayAuthorizationTokensHandler,
        customerInfoManagementService: any CustomerInfoManagementService,
        balancesService: any TangemPayBalancesService,
        withdrawTransactionService: any TangemPayWithdrawTransactionService
    ) {
        self.customerWalletId = customerWalletId
        self.customerWalletAddress = customerWalletAddress
        customerInfoSubject = CurrentValueSubject(customerInfo)
        self.keysRepository = keysRepository
        self.authorizationTokensHandler = authorizationTokensHandler
        self.customerInfoManagementService = customerInfoManagementService
        self.balancesService = balancesService
        self.withdrawTransactionService = withdrawTransactionService

        freezeUnfreezeOrderStatusPollingService = TangemPayOrderStatusPollingService(
            customerInfoManagementService: customerInfoManagementService
        )

        // No reference cycle here, self is stored as weak
        withdrawTransactionService.set(output: self)
    }

    @discardableResult
    func loadBalance() -> Task<Void, Never> {
        Task { await setupBalance() }
    }

    @discardableResult
    func loadCustomerInfo() -> Task<Void, Never> {
        runTask(in: self) { tangemPayAccount in
            do {
                let customerInfo = try await tangemPayAccount.customerInfoManagementService.loadCustomerInfo()
                tangemPayAccount.customerInfoSubject.send(customerInfo)

                if customerInfo.tangemPayStatus.isActive {
                    TangemPayOrderIdStorage.deleteCardIssuingOrderId(customerWalletId: tangemPayAccount.customerWalletId)
                    await tangemPayAccount.setupBalance()
                }
            } catch {
                VisaLogger.error("Failed to load customer info", error: error)
            }
        }
    }

    func freeze(cardId: String) async throws {
        let response = try await customerInfoManagementService.freeze(cardId: cardId)
        if response.status != .completed {
            startFreezeUnfreezeOrderStatusPolling(orderId: response.orderId)
        }
    }

    func unfreeze(cardId: String) async throws {
        let response = try await customerInfoManagementService.unfreeze(cardId: cardId)
        if response.status != .completed {
            startFreezeUnfreezeOrderStatusPolling(orderId: response.orderId)
        }
    }

    private func startFreezeUnfreezeOrderStatusPolling(orderId: String) {
        freezeUnfreezeOrderStatusPollingService.startOrderStatusPolling(
            orderId: orderId,
            interval: Constants.freezeUnfreezeOrderPollInterval,
            onCompleted: { [weak self] in
                self?.loadCustomerInfo()
            },
            onCanceled: {
                // [REDACTED_TODO_COMMENT]
            },
            onFailed: { error in
                VisaLogger.error("Failed to poll order status", error: error)
            }
        )
    }

    private func setupBalance() async {
        await balancesService.loadBalance()
    }

    private func mapToCard(visaCustomerInfoResponse: VisaCustomerInfoResponse) -> VisaCustomerInfoResponse.Card? {
        guard let card = customerInfoSubject.value.card,
              let productInstance = customerInfoSubject.value.productInstance,
              [.active, .blocked].contains(productInstance.status) else {
            return nil
        }

        return card
    }
}

// MARK: - TangemPayWithdrawTransactionServiceOutput

extension TangemPayAccount: TangemPayWithdrawTransactionServiceOutput {
    func withdrawTransactionDidSent() {
        Task {
            // Update balance after withdraw with some delay
            try await Task.sleep(for: .seconds(5))
            await setupBalance()
        }
    }
}

// MARK: - VisaCustomerInfoResponse+tangemPayStatus

private extension VisaCustomerInfoResponse {
    var tangemPayStatus: TangemPayStatus {
        if let productInstance {
            switch productInstance.status {
            case .active:
                return .active
            case .blocked:
                return .blocked
            default:
                break
            }
        }

        return .unavailable
    }
}

// MARK: - MainHeaderSupplementInfoProvider

extension TangemPayAccount: MainHeaderSupplementInfoProvider {
    var name: String {
        Localization.tangempayTitle
    }

    var walletHeaderImagePublisher: AnyPublisher<ImageType?, Never> {
        .just(output: nil)
    }

    var updatePublisher: AnyPublisher<UpdateResult, Never> {
        .empty
    }
}

private extension TangemPayAccount {
    enum Constants {
        static let freezeUnfreezeOrderPollInterval: TimeInterval = 5
    }
}

struct PaeraCustomerBuilder {
    let userWalletId: UserWalletId
    let keysRepository: KeysRepository
    let tangemPayAuthorizingInteractor: TangemPayAuthorizing
    let signer: any TangemSigner
    let authorizationService: TangemPayAuthorizationService
    let authorizationTokensHandler: TangemPayAuthorizationTokensHandler
    let customerInfoManagementService: CustomerInfoManagementService

    @Injected(\.tangemPayAuthorizationTokensRepository)
    private static var tangemPayAuthorizationTokensRepository: TangemPayAuthorizationTokensRepository

    static func make(
        userWalletId: UserWalletId,
        keysRepository: KeysRepository,
        tangemPayAuthorizingInteractor: TangemPayAuthorizing,
        signer: any TangemSigner
    ) -> PaeraCustomerBuilder {
        let authorizationService = TangemPayAPIServiceBuilder().buildTangemPayAuthorizationService()

        let customerWalletAddressAndTokens = TangemPayUtilities.getCustomerWalletAddressAndAuthorizationTokens(
            customerWalletId: userWalletId.stringValue,
            keysRepository: keysRepository
        )

        let authorizationTokensHandler = TangemPayAuthorizationTokensHandlerBuilder()
            .buildTangemPayAuthorizationTokensHandler(
                customerWalletId: userWalletId.stringValue,
                tokens: customerWalletAddressAndTokens?.tokens,
                authorizationService: authorizationService,
                authorizationTokensRepository: Self.tangemPayAuthorizationTokensRepository
            )

        let customerInfoManagementService = TangemPayCustomerInfoManagementServiceBuilder()
            .buildCustomerInfoManagementService(authorizationTokensHandler: authorizationTokensHandler)

        return PaeraCustomerBuilder(
            userWalletId: userWalletId,
            keysRepository: keysRepository,
            tangemPayAuthorizingInteractor: tangemPayAuthorizingInteractor,
            signer: signer,
            authorizationService: authorizationService,
            authorizationTokensHandler: authorizationTokensHandler,
            customerInfoManagementService: customerInfoManagementService
        )
    }

    func getIfExist() async -> PaeraCustomer? {
        let isPaeraCustomer = await isPaeraCustomer()
        guard isPaeraCustomer else {
            return nil
        }

        await MainActor.run {
            AppSettings.shared.tangemPayIsPaeraCustomer[userWalletId.stringValue] = true
        }

        return PaeraCustomer(
            userWalletId: userWalletId,
            keysRepository: keysRepository,
            tangemPayAuthorizingInteractor: tangemPayAuthorizingInteractor,
            signer: signer,
            authorizationService: authorizationService,
            authorizationTokensHandler: authorizationTokensHandler,
            customerInfoManagementService: customerInfoManagementService
        )
    }

    func create() -> PaeraCustomer {
        AppSettings.shared.tangemPayIsPaeraCustomer[userWalletId.stringValue] = true
        return PaeraCustomer(
            userWalletId: userWalletId,
            keysRepository: keysRepository,
            tangemPayAuthorizingInteractor: tangemPayAuthorizingInteractor,
            signer: signer,
            authorizationService: authorizationService,
            authorizationTokensHandler: authorizationTokensHandler,
            customerInfoManagementService: customerInfoManagementService
        )
    }

    private func isPaeraCustomer() async -> Bool {
        let customerWalletId = userWalletId.stringValue

        if await AppSettings.shared.tangemPayIsPaeraCustomer[customerWalletId, default: false] {
            return true
        }

        let availabilityService = TangemPayAPIServiceBuilder().buildTangemPayAvailabilityService()
        guard let isPaeraCustomerResponse = try? await availabilityService.isPaeraCustomer(customerWalletId: customerWalletId) else {
            return false
        }

        await MainActor.run {
            AppSettings.shared.tangemPayIsPaeraCustomer[customerWalletId] = true
            AppSettings.shared.tangemPayIsKYCHiddenForCustomerWalletId[customerWalletId] = !isPaeraCustomerResponse.isTangemPayEnabled
        }

        return true
    }
}

final class PaeraCustomer {
    private let userWalletId: UserWalletId
    private let keysRepository: KeysRepository
    private let tangemPayAuthorizingInteractor: TangemPayAuthorizing
    private let signer: any TangemSigner
    private let authorizationService: TangemPayAuthorizationService
    private let authorizationTokensHandler: TangemPayAuthorizationTokensHandler
    private let customerInfoManagementService: CustomerInfoManagementService

    private var customerWalletId: String {
        userWalletId.stringValue
    }

    fileprivate init(
        userWalletId: UserWalletId,
        keysRepository: KeysRepository,
        tangemPayAuthorizingInteractor: TangemPayAuthorizing,
        signer: any TangemSigner,
        authorizationService: TangemPayAuthorizationService,
        authorizationTokensHandler: TangemPayAuthorizationTokensHandler,
        customerInfoManagementService: CustomerInfoManagementService
    ) {
        self.userWalletId = userWalletId
        self.keysRepository = keysRepository
        self.tangemPayAuthorizingInteractor = tangemPayAuthorizingInteractor
        self.signer = signer

        self.authorizationService = authorizationService
        self.authorizationTokensHandler = authorizationTokensHandler
        self.customerInfoManagementService = customerInfoManagementService
    }

    func authorizeWithCustomerWallet() async throws {
        let response = try await tangemPayAuthorizingInteractor.authorize(
            customerWalletId: customerWalletId,
            authorizationService: authorizationService
        )
        keysRepository.update(derivations: response.derivationResult)
        try authorizationTokensHandler.saveTokens(tokens: response.tokens)
    }

    func getCurrentState() async throws -> TangemPayState {
        let customerWalletAddressAndTokens = TangemPayUtilities.getCustomerWalletAddressAndAuthorizationTokens(
            customerWalletId: customerWalletId,
            keysRepository: keysRepository
        )

        guard let customerWalletAddress = customerWalletAddressAndTokens?.customerWalletAddress,
              !authorizationTokensHandler.refreshTokenExpired
        else {
            return .syncNeeded
        }

        let customerInfo = try await customerInfoManagementService.loadCustomerInfo()

        if let productInstance = customerInfo.productInstance {
            switch productInstance.status {
            case .active, .blocked:
                return .tangemPayAccount(TangemPayAccountBuilder().build(
                    customerWalletAddress: customerWalletAddress,
                    customerInfo: customerInfo,
                    userWalletId: userWalletId,
                    keysRepository: keysRepository,
                    signer: signer,
                    authorizationTokensHandler: authorizationTokensHandler,
                    customerInfoManagementService: customerInfoManagementService
                ))

            default:
                break
            }
        }

        guard customerInfo.kyc?.status == .approved else {
            return .kyc
        }

        do {
            let orderId = try await issueCardIfNeeded(customerWalletAddress: customerWalletAddress)
            return .issuingCard(orderId: orderId)
        } catch {
            VisaLogger.error("Failed to issue card", error: error)
            return .unavailable
        }
    }

    func launchKYC(onDidDismiss: @escaping () -> Void) async throws {
        try await KYCService.start(
            getToken: customerInfoManagementService.loadKYCAccessToken,
            onDidDismiss: onDidDismiss
        )
        Analytics.log(.visaOnboardingVisaKYCFlowOpened)
    }

    func cancelKYC(onFinish: @escaping (Bool) -> Void) {
        runTask { [self] in
            do {
                try await customerInfoManagementService.cancelKYC()
                await MainActor.run {
                    AppSettings.shared.tangemPayIsKYCHiddenForCustomerWalletId[customerWalletId] = true
                }
                onFinish(true)
            } catch {
                VisaLogger.error("Failed to cancel KYC", error: error)
                onFinish(false)
            }
        }
    }

    func issueCardIfNeeded(customerWalletAddress: String) async throws -> String {
        if let cardIssuingOrderId = TangemPayOrderIdStorage.cardIssuingOrderId(customerWalletId: customerWalletId) {
            return cardIssuingOrderId
        }

        let order = try await customerInfoManagementService.placeOrder(customerWalletAddress: customerWalletAddress)
        TangemPayOrderIdStorage.saveCardIssuingOrderId(order.id, customerWalletId: customerWalletId)

        return order.id
    }
}

final class TangemPayManager {
    enum Constants {
        static let cardIssuingOrderPollInterval: TimeInterval = 60
    }

    let tangemPayNotificationManager: TangemPayNotificationManager

    var tangemPayAccount: TangemPayAccount? {
        stateSubject.value.tangemPayAccount
    }

    var tangemPayAccountPublisher: AnyPublisher<TangemPayAccount?, Never> {
        stateSubject
            .map(\.tangemPayAccount)
            .eraseToAnyPublisher()
    }

    var paeraCustomer: PaeraCustomer? {
        paeraCustomerSubject.value
    }

    var paeraCustomerPublisher: AnyPublisher<PaeraCustomer?, Never> {
        paeraCustomerSubject.eraseToAnyPublisher()
    }

    var isSyncInProgressPublisher: AnyPublisher<Bool, Never> {
        stateSubject
            .map(\.isSyncInProgress)
            .eraseToAnyPublisher()
    }

    private let paeraCustomerBuilder: PaeraCustomerBuilder

    private let stateSubject = CurrentValueSubject<TangemPayState, Never>(.initial)
    private let paeraCustomerSubject = CurrentValueSubject<PaeraCustomer?, Never>(nil)

    private lazy var cardIssuingOrderStatusPollingService = TangemPayOrderStatusPollingService(
        customerInfoManagementService: paeraCustomerBuilder.customerInfoManagementService
    )

    private var bag = Set<AnyCancellable>()

    private var customerWalletId: String {
        paeraCustomerBuilder.userWalletId.stringValue
    }

    init(
        userWalletId: UserWalletId,
        keysRepository: KeysRepository,
        tangemPayAuthorizingInteractor: TangemPayAuthorizing,
        signer: any TangemSigner
    ) {
        paeraCustomerBuilder = PaeraCustomerBuilder.make(
            userWalletId: userWalletId,
            keysRepository: keysRepository,
            tangemPayAuthorizingInteractor: tangemPayAuthorizingInteractor,
            signer: signer
        )

        tangemPayNotificationManager = TangemPayNotificationManager(
            paeraCustomerStatePublisher: stateSubject.eraseToAnyPublisher()
        )

        // No reference cycle here, self is stored as weak
        tangemPayNotificationManager.setupManager(with: self)

        bind()
        refresh()
    }

    func initializeWithNew() {
        let paeraCustomer = paeraCustomerBuilder.create()
        paeraCustomerSubject.send(paeraCustomer)
    }

    @discardableResult
    func refresh() -> Task<Void, Never> {
        runTask { [self] in
            guard let paeraCustomer = paeraCustomerSubject.value else {
                return
            }

            let state: TangemPayState
            do {
                state = try await paeraCustomer.getCurrentState()
            } catch {
                // failure events will be handled via corresponding publisher subscription
                VisaLogger.error("Failed to get current TangemPay state", error: error)
                return
            }

            stateSubject.value = state

            switch state {
            case .issuingCard(let orderId):
                startCardIssuingOrderStatusPolling(orderId: orderId)

            case .tangemPayAccount:
                cardIssuingOrderStatusPollingService.cancel()
                TangemPayOrderIdStorage.deleteCardIssuingOrderId(customerWalletId: customerWalletId)

            case .initial,
                 .syncNeeded,
                 .syncInProgress,
                 .unavailable,
                 .kyc,
                 .failedToIssueCard:
                cardIssuingOrderStatusPollingService.cancel()
            }
        }
    }

    private func startCardIssuingOrderStatusPolling(orderId: String) {
        cardIssuingOrderStatusPollingService.startOrderStatusPolling(
            orderId: orderId,
            interval: Constants.cardIssuingOrderPollInterval,
            onCompleted: { [weak self] in
                self?.refresh()
            },
            onCanceled: { [weak self] in
                self?.stateSubject.value = .failedToIssueCard
            },
            onFailed: { error in
                VisaLogger.error("Failed to poll order status", error: error)
            }
        )
    }

    private func syncTokens() {
        guard let paeraCustomer = paeraCustomerSubject.value else {
            stateSubject.value = .unavailable
            return
        }

        runTask { [self] in
            stateSubject.value = .syncInProgress
            do {
                try await paeraCustomer.authorizeWithCustomerWallet()
                do {
                    stateSubject.value = try await paeraCustomer.getCurrentState()
                } catch {
                    // failure events will be handled via corresponding publisher subscription
                    VisaLogger.error("Failed to get current TangemPay state", error: error)
                }
            } catch {
                VisaLogger.error("Failed to authorize with customer wallet", error: error)
                // [REDACTED_TODO_COMMENT]
                stateSubject.value = .syncNeeded
            }
        }
    }

    private func bind() {
        Publishers.Merge(
            paeraCustomerBuilder.authorizationTokensHandler.errorEventPublisher,
            paeraCustomerBuilder.customerInfoManagementService.errorEventPublisher
        )
        .map { event -> TangemPayState in
            switch event {
            case .unauthorized:
                .syncNeeded
            case .other:
                .unavailable
            }
        }
        .sink(receiveValue: stateSubject.send)
        .store(in: &bag)
    }
}

// MARK: - NotificationTapDelegate

extension TangemPayManager: NotificationTapDelegate {
    func didTapNotification(with id: NotificationViewId, action: NotificationButtonActionType) {
        switch action {
        case .tangemPaySync:
            syncTokens()

        default:
            break
        }
    }
}
