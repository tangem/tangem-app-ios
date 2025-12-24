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
            .compactMap(\.self?.tangemPayStatus)
            .merge(with: orderCancelledSignalSubject.mapToValue(.failedToIssue))
            .merge(with: unavailableSignalSubject.mapToValue(.unavailable))
            .eraseToAnyPublisher()
    }

    var tangemPayCardIssuingInProgressPublisher: AnyPublisher<Bool, Never> {
        TangemPayOrderIdStorage.cardIssuingOrderIdPublisher(customerWalletId: customerWalletId)
            .map { $0 != nil }
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

    lazy var tangemPayNotificationManager: TangemPayNotificationManager = .init(
        syncNeededSignalPublisher: syncNeededSignalSubject.eraseToAnyPublisher(),
        unavailableSignalPublisher: unavailableSignalSubject.eraseToAnyPublisher(),
        clearNotificationsSignalPublisher: clearNotificationsSignalSubject.eraseToAnyPublisher()
    )

    lazy var tangemPayIssuingManager: TangemPayIssuingManager = .init(
        tangemPayStatusPublisher: tangemPayStatusPublisher,
        tangemPayCardIssuingPublisher: tangemPayCardIssuingInProgressPublisher
    )

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
        customerInfoSubject.value?.depositAddress
    }

    var cardId: String? {
        customerInfoSubject.value?.productInstance?.cardId
    }

    var isPinSet: Bool {
        customerInfoSubject.value?.card?.isPinSet ?? false
    }

    let customerWalletId: String

    var cardNumberEnd: String? {
        customerInfoSubject.value?.card?.cardNumberEnd
    }

    private let keysRepository: KeysRepository
    private let authorizationTokensHandler: TangemPayAuthorizationTokensHandler
    private let balancesService: any TangemPayBalancesService

    private let customerInfoSubject = CurrentValueSubject<VisaCustomerInfoResponse?, Never>(nil)

    private let orderCancelledSignalSubject = PassthroughSubject<Void, Never>()
    private let syncNeededSignalSubject = PassthroughSubject<Void, Never>()
    private let unavailableSignalSubject = PassthroughSubject<Void, Never>()
    private let clearNotificationsSignalSubject = PassthroughSubject<Void, Never>()

    private var orderStatusPollingTask: Task<Void, Never>?
    private var bag = Set<AnyCancellable>()

    init(
        customerWalletId: String,
        customerWalletAddress: String,
        keysRepository: KeysRepository,
        authorizationTokensHandler: TangemPayAuthorizationTokensHandler,
        customerInfoManagementService: any CustomerInfoManagementService,
        balancesService: any TangemPayBalancesService,
        withdrawTransactionService: any TangemPayWithdrawTransactionService
    ) {
        self.customerWalletId = customerWalletId
        self.customerWalletAddress = customerWalletAddress
        self.keysRepository = keysRepository
        self.authorizationTokensHandler = authorizationTokensHandler
        self.customerInfoManagementService = customerInfoManagementService
        self.balancesService = balancesService
        self.withdrawTransactionService = withdrawTransactionService

        // [REDACTED_TODO_COMMENT]
        //        tangemPayNotificationManager.setupManager(with: paeraCustomer)

        // No reference cycle here, self is stored as weak
        tangemPayIssuingManager.setupDelegate(self)
        withdrawTransactionService.set(output: self)

        bind()
    }

    func getTangemPayStatus() async throws -> TangemPayStatus {
        // Since customerInfo polling starts in the init - there is no need to make another call
        for await customerInfo in await customerInfoSubject.compactMap(\.self).values {
            return customerInfo.tangemPayStatus
        }

        // This will never happen since the sequence written above will never be terminated without emitting a value
        return try await customerInfoManagementService.loadCustomerInfo().tangemPayStatus
    }

    @discardableResult
    func loadBalance() -> Task<Void, Never> {
        Task { await setupBalance() }
    }

    @discardableResult
    func loadCustomerInfo() -> Task<Void, Never> {
        runTask(in: self) { tangemPayAccount in
            do throws(CustomerInfoManagementServiceError) {
                let customerInfo = try await tangemPayAccount.customerInfoManagementService.loadCustomerInfo()
                tangemPayAccount.customerInfoSubject.send(customerInfo)

                if customerInfo.tangemPayStatus.isActive {
                    TangemPayOrderIdStorage.deleteCardIssuingOrderId(customerWalletId: tangemPayAccount.customerWalletId)
                    await tangemPayAccount.setupBalance()
                }
            } catch {
                switch error {
                case .syncNeeded:
                    tangemPayAccount.syncNeededSignalSubject.send(())
                    VisaLogger.error("Failed to load customer info", error: error)
                case .unavailable:
                    tangemPayAccount.unavailableSignalSubject.send(())
                    VisaLogger.error("Failed to load customer info", error: error)
                }
            }
        }
    }

    func freeze(cardId: String) async throws {
        let response = try await customerInfoManagementService.freeze(cardId: cardId)
        if response.status != .completed {
            startOrderStatusPolling(orderId: response.orderId, interval: Constants.freezeUnfreezeOrderPollInterval)
        }
    }

    func unfreeze(cardId: String) async throws {
        let response = try await customerInfoManagementService.unfreeze(cardId: cardId)
        if response.status != .completed {
            startOrderStatusPolling(orderId: response.orderId, interval: Constants.freezeUnfreezeOrderPollInterval)
        }
    }

    private func bind() {
//        authorizer.statePublisher
//            .withWeakCaptureOf(self)
//            .sink { tangemPayAccount, state in
//                switch state {
//                case .authorized(_, let tokens):
//                    do {
//                        try tangemPayAccount.authorizationTokensHandler.saveTokens(tokens: tokens)
//                    } catch {
//                        VisaLogger.error("Failed to save authorization tokens", error: error)
//                    }
//
//                    tangemPayAccount.loadCustomerInfo()
//
//                    if let cardIssuingOrderId = TangemPayOrderIdStorage.cardIssuingOrderId(customerWalletId: tangemPayAccount.customerWalletId) {
//                        tangemPayAccount.startOrderStatusPolling(orderId: cardIssuingOrderId, interval: Constants.cardIssuingOrderPollInterval)
//                    }
//
//                case .syncNeeded:
//                    tangemPayAccount.orderStatusPollingTask?.cancel()
//                }
//            }
//            .store(in: &bag)
    }

    private func startOrderStatusPolling(orderId: String, interval: TimeInterval) {
        orderStatusPollingTask?.cancel()

        let polling = PollingSequence(
            interval: interval,
            request: { [customerInfoManagementService] in
                try await customerInfoManagementService.getOrder(orderId: orderId)
            }
        )

        orderStatusPollingTask = runTask(in: self) { tangemPayAccount in
            for await result in polling {
                switch result {
                case .success(let order):
                    switch order.status {
                    case .new, .processing:
                        break

                    case .completed:
                        tangemPayAccount.loadCustomerInfo()
                        return

                    case .canceled:
                        tangemPayAccount.orderCancelledSignalSubject.send(())
                        return
                    }

                case .failure(let error):
                    VisaLogger.error("Failed to poll order status", error: error)
                    return
                }
            }
        }
    }

    private func createOrder() async {
        do {
            let order = try await customerInfoManagementService.placeOrder(customerWalletAddress: customerWalletAddress)
            TangemPayOrderIdStorage.saveCardIssuingOrderId(order.id, customerWalletId: customerWalletId)

            startOrderStatusPolling(orderId: order.id, interval: Constants.cardIssuingOrderPollInterval)
        } catch {
            VisaLogger.error("Failed to create order", error: error)
        }
    }

    private func setupBalance() async {
        await balancesService.loadBalance()
    }

    private func mapToCard(visaCustomerInfoResponse: VisaCustomerInfoResponse?) -> VisaCustomerInfoResponse.Card? {
        guard let card = customerInfoSubject.value?.card,
              let productInstance = customerInfoSubject.value?.productInstance,
              [.active, .blocked].contains(productInstance.status) else {
            return nil
        }

        return card
    }

    deinit {
        orderStatusPollingTask?.cancel()
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

// MARK: - TangemPayIssuingManagerDelegated

extension TangemPayAccount: TangemPayIssuingManagerDelegate {
    func createAccountAndIssueCard() {
        runTask(in: self) { tangemPayAccount in
            await tangemPayAccount.createOrder()
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

        guard case .approved = kyc?.status else {
            return .kycRequired
        }

        return .readyToIssueOrIssuing
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
        static let cardIssuingOrderPollInterval: TimeInterval = 60
        static let freezeUnfreezeOrderPollInterval: TimeInterval = 5
    }
}

struct PaeraCustomerBuilder {
    let userWalletModel: UserWalletModel

    func getIfExist() async -> PaeraCustomer? {
        let isPaeraCustomer = await isPaeraCustomer()
        guard isPaeraCustomer else {
            return nil
        }

        return PaeraCustomer(userWalletModel: userWalletModel)
    }

    private func isPaeraCustomer() async -> Bool {
        let customerWalletId = userWalletModel.userWalletId.stringValue

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
    enum State {
        case syncNeeded
        case unavailable

        case kyc
        case readyToIssueOrIssuing
        case failedToIssue
        case tangemPayAccount(TangemPayAccount)
    }

    let userWalletModel: UserWalletModel

    var statePublisher: AnyPublisher<State?, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var state: State? {
        stateSubject.value
    }

    var syncInProgressPublisher: AnyPublisher<Bool, Never> {
        syncInProgressSubject.eraseToAnyPublisher()
    }

    private let stateSubject = CurrentValueSubject<State?, Never>(nil)
    private let syncInProgressSubject = CurrentValueSubject<Bool, Never>(false)

    @Injected(\.tangemPayAuthorizationTokensRepository)
    private static var tangemPayAuthorizationTokensRepository: TangemPayAuthorizationTokensRepository

    private let authorizationService: TangemPayAuthorizationService
    private let authorizationTokensHandler: TangemPayAuthorizationTokensHandler
    private let customerInfoManagementService: CustomerInfoManagementService

    init(userWalletModel: UserWalletModel) {
        AppSettings.shared.tangemPayIsPaeraCustomer[userWalletModel.userWalletId.stringValue] = true

        self.userWalletModel = userWalletModel

        authorizationService = TangemPayAPIServiceBuilder().buildTangemPayAuthorizationService()

        let customerWalletAddressAndTokens = TangemPayUtilities.getCustomerWalletAddressAndAuthorizationTokens(
            customerWalletId: userWalletModel.userWalletId.stringValue,
            keysRepository: userWalletModel.keysRepository
        )

        authorizationTokensHandler = TangemPayAuthorizationTokensHandlerBuilder()
            .buildTangemPayAuthorizationTokensHandler(
                customerWalletId: userWalletModel.userWalletId.stringValue,
                tokens: customerWalletAddressAndTokens?.tokens,
                authorizationService: authorizationService,
                authorizationTokensRepository: Self.tangemPayAuthorizationTokensRepository
            )

        customerInfoManagementService = TangemPayCustomerInfoManagementServiceBuilder()
            .buildCustomerInfoManagementService(authorizationTokensHandler: authorizationTokensHandler)

        updateState()
    }

    @discardableResult
    func updateState() -> Task<Void, Never> {
        runTask { [self] in
            stateSubject.send(await getCurrentState())
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
                    AppSettings.shared.tangemPayIsKYCHiddenForCustomerWalletId[userWalletModel.userWalletId.stringValue] = true
                }
                onFinish(true)
            } catch {
                VisaLogger.error("Failed to cancel KYC", error: error)
                onFinish(false)
            }
        }
    }

    @discardableResult
    func authorizeWithCustomerWallet() async throws -> State {
        let response = try await userWalletModel.tangemPayAuthorizingInteractor.authorize(
            customerWalletId: userWalletModel.userWalletId.stringValue,
            authorizationService: authorizationService
        )
        userWalletModel.keysRepository.update(derivations: response.derivationResult)
        try authorizationTokensHandler.saveTokens(tokens: response.tokens)

        let currentState = await getCurrentState()
        stateSubject.send(currentState)
        return currentState
    }

    func getCurrentState() async -> State {
        let customerWalletAddressAndTokens = TangemPayUtilities.getCustomerWalletAddressAndAuthorizationTokens(
            customerWalletId: userWalletModel.userWalletId.stringValue,
            keysRepository: userWalletModel.keysRepository
        )

        guard let customerWalletAddress = customerWalletAddressAndTokens?.customerWalletAddress,
              let tokens = authorizationTokensHandler.tokens,
              !tokens.refreshTokenExpired
        else {
            return .syncNeeded
        }

        let customerInfo: VisaCustomerInfoResponse
        do {
            customerInfo = try await customerInfoManagementService.loadCustomerInfo()
        } catch {
            switch error {
            case .syncNeeded:
                return .syncNeeded
            case .unavailable:
                return .unavailable
            }
        }

        if let productInstance = customerInfo.productInstance {
            switch productInstance.status {
            case .active, .blocked:
                let account = TangemPayAccountBuilderr(
                    customerWalletAddress: customerWalletAddress,
                    userWalletModel: userWalletModel,
                    paeraCustomer: self,
                    authorizationTokensHandler: authorizationTokensHandler,
                    customerInfoManagementService: customerInfoManagementService
                )
                .build()

                return .tangemPayAccount(account)

            default:
                break
            }
        }

        if customerInfo.kyc?.status == .approved {
            return .readyToIssueOrIssuing
        }

        return .kyc
    }
}

// MARK: - NotificationTapDelegate

extension PaeraCustomer: NotificationTapDelegate {
    func didTapNotification(with id: NotificationViewId, action: NotificationButtonActionType) {
        switch action {
        case .tangemPaySync:
            runTask { [self] in
                syncInProgressSubject.value = true
                do {
                    try await authorizeWithCustomerWallet()
                } catch {
                    VisaLogger.error("Failed to authorize with customer wallet", error: error)
                    stateSubject.value = .unavailable
                }
                syncInProgressSubject.value = false
            }

        default:
            break
        }
    }
}

struct TangemPayAccountBuilderr {
    let customerWalletAddress: String
    let userWalletModel: UserWalletModel
    let paeraCustomer: PaeraCustomer

    let authorizationTokensHandler: TangemPayAuthorizationTokensHandler
    let customerInfoManagementService: CustomerInfoManagementService

    func build() -> TangemPayAccount {
        let tokenBalancesRepository = CommonTokenBalancesRepository(
            userWalletId: userWalletModel.userWalletId
        )

        let balancesService = CommonTangemPayBalanceService(
            customerInfoManagementService: customerInfoManagementService,
            tokenBalancesRepository: tokenBalancesRepository
        )

        let withdrawTransactionService = CommonTangemPayWithdrawTransactionService(
            customerInfoManagementService: customerInfoManagementService,
            fiatItem: TangemPayUtilities.fiatItem,
            signer: userWalletModel.signer
        )

        return TangemPayAccount(
            customerWalletId: paeraCustomer.userWalletModel.userWalletId.stringValue,
            customerWalletAddress: customerWalletAddress,
            keysRepository: paeraCustomer.userWalletModel.keysRepository,
            authorizationTokensHandler: authorizationTokensHandler,
            customerInfoManagementService: customerInfoManagementService,
            balancesService: balancesService,
            withdrawTransactionService: withdrawTransactionService
        )
    }
}
