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
            do throws(CustomerInfoManagementServiceError) {
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

import TangemMacro

final class PaeraCustomer {
    @CaseFlagable
    enum State {
        case syncNeeded
        case syncInProgress
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

    lazy var tangemPayNotificationManager = TangemPayNotificationManager(paeraCustomerStatePublisher: statePublisher)

    private let stateSubject = CurrentValueSubject<State?, Never>(nil)

    private let orderCancelledSignalSubject = PassthroughSubject<Void, Never>()

    @Injected(\.tangemPayAuthorizationTokensRepository)
    private static var tangemPayAuthorizationTokensRepository: TangemPayAuthorizationTokensRepository

    private let authorizationService: TangemPayAuthorizationService
    private let authorizationTokensHandler: TangemPayAuthorizationTokensHandler
    private let customerInfoManagementService: CustomerInfoManagementService

    private let cardIssuingOrderStatusPollingService: TangemPayOrderStatusPollingService

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

        cardIssuingOrderStatusPollingService = TangemPayOrderStatusPollingService(customerInfoManagementService: customerInfoManagementService)

        // No reference cycle here, self is stored as weak
        tangemPayNotificationManager.setupManager(with: self)

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
            cardIssuingOrderStatusPollingService.cancel()
            return .syncNeeded
        }

        let customerInfo: VisaCustomerInfoResponse
        do {
            customerInfo = try await customerInfoManagementService.loadCustomerInfo()
        } catch {
            switch error {
            case .syncNeeded:
                cardIssuingOrderStatusPollingService.cancel()
                return .syncNeeded

            case .unavailable:
                cardIssuingOrderStatusPollingService.cancel()
                return .unavailable
            }
        }

        if let productInstance = customerInfo.productInstance {
            switch productInstance.status {
            case .active, .blocked:
                let account = TangemPayAccountBuilderr(
                    customerWalletAddress: customerWalletAddress,
                    customerInfo: customerInfo,
                    userWalletModel: userWalletModel,
                    authorizationTokensHandler: authorizationTokensHandler,
                    customerInfoManagementService: customerInfoManagementService
                )
                .build()

                TangemPayOrderIdStorage.deleteCardIssuingOrderId(customerWalletId: userWalletModel.userWalletId.stringValue)
                return .tangemPayAccount(account)

            default:
                break
            }
        }

        guard customerInfo.kyc?.status == .approved else {
            return .kyc
        }

        let customerWalletId = userWalletModel.userWalletId.stringValue

        if let cardIssuingOrderId = TangemPayOrderIdStorage.cardIssuingOrderId(customerWalletId: customerWalletId) {
            startCardIssuingOrderStatusPolling(orderId: cardIssuingOrderId)
        } else {
            do {
                let order = try await customerInfoManagementService.placeOrder(customerWalletAddress: customerWalletAddress)
                TangemPayOrderIdStorage.saveCardIssuingOrderId(order.id, customerWalletId: customerWalletId)
                startCardIssuingOrderStatusPolling(orderId: order.id)
            } catch {
                VisaLogger.error("Failed to create order", error: error)
            }
        }

        return .readyToIssueOrIssuing
    }

    private func startCardIssuingOrderStatusPolling(orderId: String) {
        cardIssuingOrderStatusPollingService.startOrderStatusPolling(
            orderId: orderId,
            interval: Constants.cardIssuingOrderPollInterval,
            onCompleted: { [weak self] in
                self?.updateState()
            },
            onCanceled: { [weak self] in
                self?.orderCancelledSignalSubject.send(())
            },
            onFailed: { error in
                VisaLogger.error("Failed to poll order status", error: error)
            }
        )
    }
}

// MARK: - NotificationTapDelegate

extension PaeraCustomer: NotificationTapDelegate {
    func didTapNotification(with id: NotificationViewId, action: NotificationButtonActionType) {
        switch action {
        case .tangemPaySync:
            runTask { [self] in
                stateSubject.value = .syncInProgress
                do {
                    // Changes state under the hood
                    try await authorizeWithCustomerWallet()
                } catch {
                    VisaLogger.error("Failed to authorize with customer wallet", error: error)
                    stateSubject.value = .unavailable
                }
            }

        default:
            break
        }
    }
}

struct TangemPayAccountBuilderr {
    let customerWalletAddress: String
    let customerInfo: VisaCustomerInfoResponse
    let userWalletModel: UserWalletModel

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
            customerWalletId: userWalletModel.userWalletId.stringValue,
            customerWalletAddress: customerWalletAddress,
            customerInfo: customerInfo,
            keysRepository: userWalletModel.keysRepository,
            authorizationTokensHandler: authorizationTokensHandler,
            customerInfoManagementService: customerInfoManagementService,
            balancesService: balancesService,
            withdrawTransactionService: withdrawTransactionService
        )
    }
}

private extension PaeraCustomer {
    enum Constants {
        static let cardIssuingOrderPollInterval: TimeInterval = 60
    }
}

final class TangemPayOrderStatusPollingService {
    private let customerInfoManagementService: CustomerInfoManagementService

    private var orderStatusPollingTask: Task<Void, Never>?

    init(customerInfoManagementService: CustomerInfoManagementService) {
        self.customerInfoManagementService = customerInfoManagementService
    }

    func startOrderStatusPolling(
        orderId: String,
        interval: TimeInterval,
        onCompleted: @escaping () -> Void,
        onCanceled: @escaping () -> Void,
        onFailed: @escaping (Error) -> Void
    ) {
        orderStatusPollingTask?.cancel()

        let polling = PollingSequence(
            interval: interval,
            request: { [customerInfoManagementService] in
                try await customerInfoManagementService.getOrder(orderId: orderId)
            }
        )

        orderStatusPollingTask = runTask {
            for await result in polling {
                switch result {
                case .success(let order):
                    switch order.status {
                    case .new, .processing:
                        break

                    case .completed:
                        onCompleted()
                        return

                    case .canceled:
                        onCanceled()
                        return
                    }

                case .failure(let error):
                    onFailed(error)
                    return
                }
            }
        }
    }

    func cancel() {
        orderStatusPollingTask?.cancel()
    }

    deinit {
        orderStatusPollingTask?.cancel()
    }
}
