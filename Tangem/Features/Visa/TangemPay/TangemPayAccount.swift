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
            .eraseToAnyPublisher()
    }

    var tangemPayAccountStatePublisher: AnyPublisher<TangemPayAuthorizer.State, Never> {
        authorizer.statePublisher
    }

    var tangemPayCardIssuingInProgressPublisher: AnyPublisher<Bool, Never> {
        authorizer.statePublisher
            .compactMap(\.authorized)
            .flatMapLatest { customerWalletAddress, _ in
                TangemPayOrderIdStorage.cardIssuingOrderIdPublisher(customerWalletAddress: customerWalletAddress)
            }
            .map { $0 != nil }
            .eraseToAnyPublisher()
    }

    var tangemPaySyncInProgressPublisher: AnyPublisher<Bool, Never> {
        syncInProgressSubject.eraseToAnyPublisher()
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
        tangemPayAccountStatePublisher: authorizer.statePublisher
    )

    lazy var tangemPayIssuingManager: TangemPayIssuingManager = .init(
        tangemPayStatusPublisher: tangemPayStatusPublisher,
        tangemPayCardIssuingPublisher: tangemPayCardIssuingInProgressPublisher
    )

    // MARK: - Balances

    lazy var tangemPayTokenBalanceProvider: TokenBalanceProvider = TangemPayTokenBalanceProvider(
        walletModelId: .init(tokenItem: TangemPayUtilities.usdcTokenItem),
        tokenBalancesRepository: tokenBalancesRepository,
        balanceSubject: balanceSubject
    )

    lazy var tangemPayMainHeaderBalanceProvider: MainHeaderBalanceProvider = TangemPayMainHeaderBalanceProvider(
        tangemPayTokenBalanceProvider: tangemPayTokenBalanceProvider
    )

    lazy var tangemPayMainHeaderSubtitleProvider: MainHeaderSubtitleProvider = TangemPayMainHeaderSubtitleProvider(
        balanceSubject: balanceSubject
    )

    let customerInfoManagementService: any CustomerInfoManagementService

    var depositAddress: String? {
        customerInfoSubject.value?.depositAddress
    }

    var cardId: String? {
        customerInfoSubject.value?.productInstance?.cardId
    }

    var customerWalletAddress: String? {
        state.authorized?.customerWalletAddress
    }

    var cardNumberEnd: String? {
        customerInfoSubject.value?.card?.cardNumberEnd
    }

    var state: TangemPayAuthorizer.State {
        authorizer.state
    }

    @Injected(\.tangemPayAuthorizationTokensRepository)
    private var tangemPayAuthorizationTokensRepository: TangemPayAuthorizationTokensRepository

    private let authorizationTokensHandler: TangemPayAuthorizationTokensHandler
    private let authorizer: TangemPayAuthorizer

    private let tokenBalancesRepository: TokenBalancesRepository

    private let customerInfoSubject = CurrentValueSubject<VisaCustomerInfoResponse?, Never>(nil)
    private let balanceSubject = CurrentValueSubject<LoadingResult<TangemPayBalance, Error>, Never>(.loading)

    private let orderCancelledSignalSubject = PassthroughSubject<Void, Never>()
    private let syncInProgressSubject = CurrentValueSubject<Bool, Never>(false)

    private var orderStatusPollingTask: Task<Void, Never>?
    private var accountStateObservingCancellable: Cancellable?

    init(
        authorizer: TangemPayAuthorizer,
        tokenBalancesRepository: TokenBalancesRepository
    ) {
        self.authorizer = authorizer
        self.tokenBalancesRepository = tokenBalancesRepository

        authorizationTokensHandler = TangemPayAuthorizationTokensHandlerBuilder()
            .buildTangemPayAuthorizationTokensHandler(
                customerWalletId: authorizer.customerWalletId,
                authorizationService: authorizer.authorizationService,
                setSyncNeeded: authorizer.setSyncNeeded,
                setUnavailable: authorizer.setUnavailable
            )

        customerInfoManagementService = TangemPayCustomerInfoManagementServiceBuilder()
            .buildCustomerInfoManagementService(authorizationTokensHandler: authorizationTokensHandler)

        // No reference cycle here, self is stored as weak in all three entities
        tangemPayNotificationManager.setupManager(with: self)
        authorizationTokensHandler.setupAuthorizationTokensSaver(self)
        tangemPayIssuingManager.setupDelegate(self)

        accountStateObservingCancellable = authorizer.statePublisher
            .withWeakCaptureOf(self)
            .sink { tangemPayAccount, state in
                switch state {
                case .authorized(let customerWalletAddress, let tokens):
                    do {
                        try tangemPayAccount.authorizationTokensHandler.saveTokens(tokens: tokens)
                    } catch {
                        VisaLogger.error("Failed to save authorization tokens", error: error)
                    }

                    tangemPayAccount.loadCustomerInfo()

                    if let cardIssuingOrderId = TangemPayOrderIdStorage.cardIssuingOrderId(customerWalletAddress: customerWalletAddress) {
                        tangemPayAccount.startOrderStatusPolling(orderId: cardIssuingOrderId, interval: Constants.cardIssuingOrderPollInterval)
                    }

                case .syncNeeded, .unavailable:
                    tangemPayAccount.orderStatusPollingTask?.cancel()
                }
            }
    }

    convenience init?(
        userWalletId: UserWalletId,
        keysRepository: KeysRepository,
        tangemPayAuthorizingInteractor: TangemPayAuthorizing
    ) async {
        let customerWalletId = userWalletId.stringValue
        let availabilityService = TangemPayAPIServiceBuilder().buildTangemPayAvailabilityService()

        let state: TangemPayAuthorizer.State
        let tokenBalancesRepository = CommonTokenBalancesRepository(userWalletId: userWalletId)

        do {
            _ = try await availabilityService.isPaeraCustomer(customerWalletId: customerWalletId)
            await MainActor.run {
                AppSettings.shared.tangemPayIsPaeraCustomer[customerWalletId] = true
            }

            if let (customerWalletAddress, tokens) = TangemPayUtilities.getCustomerWalletAddressAndAuthorizationTokens(
                customerWalletId: customerWalletId,
                keysRepository: keysRepository
            ) {
                state = .authorized(customerWalletAddress: customerWalletAddress, tokens: tokens)
            } else {
                state = .syncNeeded
            }
        } catch {
            if await AppSettings.shared.tangemPayIsPaeraCustomer[customerWalletId, default: false] {
                state = .unavailable
            } else {
                return nil
            }
        }

        let authorizer = TangemPayAuthorizer(
            customerWalletId: customerWalletId,
            interactor: tangemPayAuthorizingInteractor,
            keysRepository: keysRepository,
            state: state
        )

        self.init(authorizer: authorizer, tokenBalancesRepository: tokenBalancesRepository)
    }

    func launchKYC(onDidDismiss: @escaping () -> Void) async throws {
        try await KYCService.start(
            getToken: customerInfoManagementService.loadKYCAccessToken,
            onDidDismiss: onDidDismiss
        )
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
            do {
                let customerInfo = try await tangemPayAccount.customerInfoManagementService.loadCustomerInfo()
                tangemPayAccount.customerInfoSubject.send(customerInfo)

                if customerInfo.tangemPayStatus.isActive {
                    if let customerWalletAddress = tangemPayAccount.customerWalletAddress {
                        TangemPayOrderIdStorage.deleteCardIssuingOrderId(customerWalletAddress: customerWalletAddress)
                    }
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
            startOrderStatusPolling(orderId: response.orderId, interval: Constants.freezeUnfreezeOrderPollInterval)
        }
    }

    func unfreeze(cardId: String) async throws {
        let response = try await customerInfoManagementService.unfreeze(cardId: cardId)
        if response.status != .completed {
            startOrderStatusPolling(orderId: response.orderId, interval: Constants.freezeUnfreezeOrderPollInterval)
        }
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
        guard let customerWalletAddress else {
            VisaLogger.info("Failed to create order. `customerWalletAddress` was unexpectedly nil")
            return
        }

        do {
            let order = try await customerInfoManagementService.placeOrder(customerWalletAddress: customerWalletAddress)
            TangemPayOrderIdStorage.saveCardIssuingOrderId(order.id, customerWalletAddress: customerWalletAddress)

            startOrderStatusPolling(orderId: order.id, interval: Constants.cardIssuingOrderPollInterval)
        } catch {
            VisaLogger.error("Failed to create order", error: error)
        }
    }

    private func setupBalance() async {
        do {
            balanceSubject.send(.loading)
            let balance = try await customerInfoManagementService.getBalance()
            balanceSubject.send(.success(balance))
        } catch {
            balanceSubject.send(.failure(error))
        }
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

// MARK: - TangemPayAuthorizationTokensSaver

extension TangemPayAccount: TangemPayAuthorizationTokensSaver {
    func saveAuthorizationTokensToStorage(tokens: TangemPayAuthorizationTokens, customerWalletId: String) throws {
        try tangemPayAuthorizationTokensRepository.save(tokens: tokens, customerWalletId: customerWalletId)
    }
}

// MARK: - NotificationTapDelegate

extension TangemPayAccount: NotificationTapDelegate {
    func didTapNotification(with id: NotificationViewId, action: NotificationButtonActionType) {
        switch action {
        case .tangemPaySync:
            runTask { [self] in
                syncInProgressSubject.value = true
                do {
                    try await authorizer.authorizeWithCustomerWallet()
                } catch {
                    VisaLogger.error("Failed to authorize with customer wallet", error: error)
                }
                syncInProgressSubject.value = false
            }

        default:
            break
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

        guard case .approved = kyc.status else {
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

struct TangemPayCardDetails {
    let card: VisaCustomerInfoResponse.Card
    let balance: TangemPayBalance
}
