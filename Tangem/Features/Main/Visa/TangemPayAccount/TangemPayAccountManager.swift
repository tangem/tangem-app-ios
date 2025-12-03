//
//  TangemPayAccountManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemVisa
import TangemFoundation
import Combine

final class TangemPayAccountManager {
    private let walletInfo: WalletInfo
    private let userWalletId: UserWalletId
    private let config: UserWalletConfig
    private let keysRepository: KeysRepository
    private let updatePublisher: AnyPublisher<UpdateResult, Never>
    private let orderCancelledSignalSubject = PassthroughSubject<Void, Never>()

    @Injected(\.tangemPayAuthorizationTokensRepository)
    private var tangemPayAuthorizationTokensRepository: TangemPayAuthorizationTokensRepository

    private var authorizationTokensHandler: TangemPayAuthorizationTokensHandler?
    private var customerInfoManagementService: CustomerInfoManagementService?
    private var authorizer: TangemPayAuthorizer?

    private var orderStatusPollingTask: Task<Void, Never>?
    private var accountStateObservingCancellable: Cancellable?

    private var customerWalletId: String {
        userWalletId.stringValue
    }

    private var signer: TangemSigner {
        config.tangemSigner
    }

    private lazy var tangemPayIssuingManager: TangemPayIssuingManager = .init(
        tangemPayStatusPublisher: tangemPayStatusPublisher,
        tangemPayCardIssuingPublisher: tangemPayCardIssuingInProgressPublisher
    )

    @Published private(set) var state: State = .idle
    @Published private var authorized: Authorized? = nil
    @Published private var customerInfo: VisaCustomerInfoResponse? = nil
    @Published private var syncInProgress: Bool = false

    let notificationManager = TangemPayNotificationManager()

    var statePublisher: AnyPublisher<State, Never> {
        $state
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var tangemPaySyncInProgressPublisher: AnyPublisher<Bool, Never> {
        $syncInProgress.eraseToAnyPublisher()
    }

    var tangemPayStatusPublisher: AnyPublisher<TangemPayStatus, Never> {
        $customerInfo
            .compactMap(\.self?.tangemPayStatus)
            .merge(with: orderCancelledSignalSubject.mapToValue(.failedToIssue))
            .eraseToAnyPublisher()
    }

    var tangemPayCardIssuingInProgressPublisher: AnyPublisher<Bool, Never> {
        TangemPayOrderIdStorage.cardIssuingOrderIdPublisher(customerWalletId: customerWalletId)
            .map { $0 != nil }
            .eraseToAnyPublisher()
    }

    var notificationInputs: [NotificationViewInput] = []

    init(
        walletInfo: WalletInfo,
        config: UserWalletConfig,
        userWalletId: UserWalletId,
        keysRepository: KeysRepository,
        updatePublisher: AnyPublisher<UpdateResult, Never>
    ) {
        self.walletInfo = walletInfo
        self.userWalletId = userWalletId
        self.config = config
        self.keysRepository = keysRepository
        self.updatePublisher = updatePublisher

        tangemPayIssuingManager.setupDelegate(self)
        notificationManager.setupManager(with: self)

        runTask(in: self) { manager in
            await manager.initializeAuthorizer()
        }
    }

    deinit {
        orderStatusPollingTask?.cancel()
    }

    func freeze(cardId: String) async throws {
        guard let customerInfoManagementService else {
            throw Error.authorizerNotFound
        }
        let response = try await customerInfoManagementService.freeze(cardId: cardId)
        if response.status != .completed {
            startOrderStatusPolling(
                orderId: response.orderId,
                interval: Constants.freezeUnfreezeOrderPollInterval
            )
        }
    }

    func unfreeze(cardId: String) async throws {
        guard let customerInfoManagementService else {
            throw Error.authorizerNotFound
        }
        let response = try await customerInfoManagementService.unfreeze(cardId: cardId)
        if response.status != .completed {
            startOrderStatusPolling(orderId: response.orderId, interval: Constants.freezeUnfreezeOrderPollInterval)
        }
    }

    func setPin(pin: String, sessionId: String, iv: String) async throws -> TangemPaySetPinResponse {
        guard let customerInfoManagementService else {
            throw Error.authorizerNotFound
        }

        return try await customerInfoManagementService.setPin(
            pin: pin,
            sessionId: sessionId,
            iv: iv
        )
    }

    func launchKYC() async throws {
        guard let customerInfoManagementService else {
            throw Error.authorizerNotFound
        }

        try await KYCService.start(
            getToken: customerInfoManagementService.loadKYCAccessToken,
            onDidDismiss: { [weak self] in
                self?.loadCustomerInfo()
            }
        )
    }

    func onTangemPaySync() {
        runTask(in: self) { manager in
            manager.syncInProgress = true
            do {
                try await manager.authorizeWithCustomerWallet()
            } catch {
                VisaLogger.error("Failed to authorize with customer wallet", error: error)
            }
            manager.syncInProgress = false
        }
    }

    func onTangemPayOfferAccepted(_ onFinish: @escaping () -> Void) async throws {
        runTask(in: self) { manager in
            do {
                switch manager.state {
                case .unavailable:
                    await manager.initializeAuthorizer()
                case .offered(let status):
                    switch status {
                    case .kycRequired:
                        try await manager.launchKYC()
                    case .readyToIssueOrIssuing:
                        break
                    case .failedToIssue:
                        break
                    case .active, .blocked:
                        break
                    }
                case .syncNeeded:
                    try await manager.authorizeWithCustomerWallet()
                case .activated, .idle:
                    break
                }
            } catch {
                VisaLogger.error("Failed to accept offer", error: error)
            }
            onFinish()
        }
    }

    private func initializeAuthorizer() async {
        guard FeatureProvider.isAvailable(.visa) else { return }
        let walletId = userWalletId.stringValue

        do {
            let isPaeraCustomer = await isPaeraCustomer(
                walletId: walletId
            )

            let accountBuilder = TangemPayAccountBuilder()
            let authorizer = try await accountBuilder.makeTangemPayAuthorizer(
                authorizerType: isPaeraCustomer ? .paeraCustomer : .availability,
                userWalletId: userWalletId,
                keysRepository: keysRepository,
                tangemPayAuthorizingInteractor: tangemPayAuthorizingInteractor,
                signer: signer
            )

            let authorizationTokensHandler = accountBuilder
                .buildAuthorizationTokenHandler(authorizer: authorizer)
            setupAuthorizationTokenHandler(authorizationTokensHandler)

            customerInfoManagementService = TangemPayCustomerInfoManagementServiceBuilder()
                .buildCustomerInfoManagementService(
                    authorizationTokensHandler: authorizationTokensHandler
                )

            bindAuthorizer(authorizer)
        } catch {
            state = .unavailable
        }
    }

    private func authorizeWithCustomerWallet() async throws {
        guard let authorizer else {
            throw Error.authorizerNotFound
        }

        try await authorizer.authorizeWithCustomerWallet()
    }

    private func setupAuthorizationTokenHandler(_ handler: TangemPayAuthorizationTokensHandler) {
        authorizationTokensHandler = handler
        handler.setupAuthorizationTokensSaver(self)
    }

    private func bindAuthorizer(_ authorizer: TangemPayAuthorizer) {
        self.authorizer = authorizer

        authorizer.statePublisher
            .compactMap { $0.authorized }
            .assign(to: &$authorized)

        notificationManager
            .bind(tangemPayAccountStatePublisher: authorizer.statePublisher)

        accountStateObservingCancellable = authorizer.statePublisher
            .withWeakCaptureOf(self)
            .sink { manager, state in
                switch state {
                case .authorized(_, let tokens):
                    do {
                        guard let tokensHandler = manager.authorizationTokensHandler else {
                            throw Error.authorizerNotFound
                        }
                        try tokensHandler.saveTokens(tokens: tokens)
                    } catch {
                        VisaLogger.error("Failed to save authorization tokens", error: error)
                    }

                    manager.loadCustomerInfo()

                    if let cardIssuingOrderId = TangemPayOrderIdStorage
                        .cardIssuingOrderId(
                            customerWalletId: manager.customerWalletId
                        ) {
                        manager.startOrderStatusPolling(
                            orderId: cardIssuingOrderId,
                            interval: Constants.cardIssuingOrderPollInterval
                        )
                    }

                case .syncNeeded, .unavailable:
                    manager.orderStatusPollingTask?.cancel()
                }
            }

        let authorizerState = authorizer.statePublisher
            .compactMap { state -> State? in
                switch state {
                case .syncNeeded:
                    return .syncNeeded
                case .unavailable:
                    return .unavailable
                case .authorized:
                    return nil
                }
            }
            .removeDuplicates()
            .eraseToAnyPublisher()

        let customerInfoState = $customerInfo
            .compactMap { info -> State? in
                if case .kycRequired = info?.tangemPayStatus {
                    return .offered(.kycRequired)
                }
                return nil
            }
            .removeDuplicates()
            .eraseToAnyPublisher()

        Publishers.Merge(
            authorizerState,
            customerInfoState
        )
        .assign(to: &$state)
    }

    @discardableResult
    func loadCustomerInfo() -> Task<Void, Never> {
        runTask(in: self) { manager in
            do {
                guard
                    let customerInfoManagementService = manager.customerInfoManagementService
                else {
                    throw Error.authorizerNotFound
                }

                let customerInfo = try await customerInfoManagementService.loadCustomerInfo()
                manager.customerInfo = customerInfo

                if customerInfo.tangemPayStatus.isActive {
                    TangemPayOrderIdStorage.deleteCardIssuingOrderId(
                        customerWalletId: manager.customerWalletId
                    )

                    try await manager.buildAccount()
                } else {
                    manager.state = .offered(customerInfo.tangemPayStatus)
                }
            } catch {
                VisaLogger.error("Failed to load customer info", error: error)
            }
        }
    }

    private func buildAccount() async throws {
        guard let authorizer, let customerInfoManagementService else {
            throw Error.authorizerNotFound
        }

        let account = try await TangemPayAccountBuilder().makeTangemPayAccount(
            authorizer: authorizer,
            userWalletId: userWalletId,
            keysRepository: keysRepository,
            tangemPayAuthorizingInteractor: tangemPayAuthorizingInteractor,
            signer: signer,
            customerInfoManagementService: customerInfoManagementService
        )

        $customerInfo
            .removeDuplicates()
            .assign(to: &account.$customerInfo)

        state = .activated(account)
    }

    private func startOrderStatusPolling(orderId: String, interval: TimeInterval) {
        orderStatusPollingTask?.cancel()
        guard let customerInfoManagementService else {
            return
        }

        let polling = PollingSequence(
            interval: interval,
            request: { [customerInfoManagementService] in
                try await customerInfoManagementService.getOrder(orderId: orderId)
            }
        )

        orderStatusPollingTask = runTask(in: self) { manager in
            for await result in polling {
                switch result {
                case .success(let order):
                    switch order.status {
                    case .new, .processing:
                        break

                    case .completed:
                        manager.loadCustomerInfo()
                        return

                    case .canceled:
                        manager.orderCancelledSignalSubject.send(())
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
        guard let customerInfoManagementService else {
            return
        }
        guard let customerWalletAddress = authorized?.customerWalletAddress else {
            VisaLogger.info("Failed to create order. `customerWalletAddress` was unexpectedly nil")
            return
        }

        guard
            TangemPayOrderIdStorage.cardIssuingOrderId(customerWalletId: customerWalletId) == nil
        else {
            return
        }

        do {
            let order = try await customerInfoManagementService.placeOrder(
                customerWalletAddress: customerWalletAddress
            )
            TangemPayOrderIdStorage.saveCardIssuingOrderId(order.id, customerWalletId: customerWalletId)

            startOrderStatusPolling(
                orderId: order.id,
                interval: Constants.cardIssuingOrderPollInterval
            )
        } catch {
            VisaLogger.error("Failed to create order", error: error)
        }
    }

    private func isPaeraCustomer(
        walletId: String,
    ) async -> Bool {
        do {
            _ = try await TangemPayAPIServiceBuilder()
                .buildTangemPayAvailabilityService()
                .isPaeraCustomer(customerWalletId: walletId)
            return true
        } catch {
            return false
        }
    }
}

extension TangemPayAccountManager {
    typealias State = TangemPayAccountManagingState
}

extension TangemPayAccountManager: TangemPayAccountManaging {
    var tangemPayAuthorizingInteractor: TangemPayAuthorizing {
        switch walletInfo {
        case .cardWallet(let cardInfo):
            return TangemPayAuthorizingCardInteractor(with: cardInfo)
        case .mobileWallet:
            return TangemPayAuthorizingMobileWalletInteractor(
                userWalletId: userWalletId,
                userWalletConfig: config
            )
        }
    }

    var tangemPayAccount: TangemPayAccount? {
        state.account
    }

    var tangemPayAccountPublisher: AnyPublisher<TangemPayAccount, Never> {
        $state
            .compactMap { $0.account }
            .eraseToAnyPublisher()
    }
}

extension TangemPayAccountManager: TangemPayIssuingManagerDelegate {
    func createAccountAndIssueCard() {
        runTask(in: self) { manager in
            await manager.createOrder()
        }
    }
}

extension TangemPayAccountManager: NotificationTapDelegate {
    func didTapNotification(with id: NotificationViewId, action: NotificationButtonActionType) {
        switch action {
        case .tangemPaySync:
            onTangemPaySync()
        default:
            break
        }
    }
}

extension TangemPayAccountManager: TangemPayAuthorizationTokensSaver {
    func saveAuthorizationTokensToStorage(
        tokens: TangemVisa.TangemPayAuthorizationTokens,
        customerWalletId: String
    ) throws {
        try tangemPayAuthorizationTokensRepository.save(tokens: tokens, customerWalletId: customerWalletId)
    }
}

private extension TangemPayAccountManager {
    typealias Authorized = (customerWalletAddress: String, tokens: TangemPayAuthorizationTokens)

    enum Constants {
        static let cardIssuingOrderPollInterval: TimeInterval = 60
        static let freezeUnfreezeOrderPollInterval: TimeInterval = 5
    }

    enum Error: LocalizedError {
        case authorizerNotFound
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
