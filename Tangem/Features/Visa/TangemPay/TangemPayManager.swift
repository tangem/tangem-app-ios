//
//  TangemPayManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemVisa

final class TangemPayManager {
    let tangemPayNotificationManager: TangemPayNotificationManager

    var state: TangemPayLocalState {
        stateSubject.value
    }

    var statePublisher: AnyPublisher<TangemPayLocalState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    @Injected(\.tangemPayAuthorizationTokensRepository)
    private static var tangemPayAuthorizationTokensRepository: TangemPayAuthorizationTokensRepository

    private let userWalletId: UserWalletId
    private let keysRepository: KeysRepository
    private let authorizingInteractor: TangemPayAuthorizing
    private let signer: any TangemSigner
    private let authorizationService: TangemPayAuthorizationService
    private let customerInfoManagementService: CustomerInfoManagementService
    private let remoteStateFetcher: TangemPayEnrollmentStateFetcher

    private let stateSubject = CurrentValueSubject<TangemPayLocalState, Never>(.initial)

    private lazy var cardIssuingOrderStatusPollingService = TangemPayOrderStatusPollingService(
        customerInfoManagementService: customerInfoManagementService
    )

    private var bag = Set<AnyCancellable>()

    private var customerWalletId: String {
        userWalletId.stringValue
    }

    private var customerWalletAddress: String? {
        TangemPayUtilities.getCustomerWalletAddressAndAuthorizationTokens(
            customerWalletId: userWalletId.stringValue,
            keysRepository: keysRepository
        )?
            .customerWalletAddress
    }

    init(
        userWalletId: UserWalletId,
        keysRepository: KeysRepository,
        authorizingInteractor: TangemPayAuthorizing,
        signer: any TangemSigner
    ) {
        self.userWalletId = userWalletId
        self.keysRepository = keysRepository
        self.authorizingInteractor = authorizingInteractor
        self.signer = signer

        tangemPayNotificationManager = TangemPayNotificationManager(
            paeraCustomerStatePublisher: stateSubject.eraseToAnyPublisher()
        )

        let customerWalletAddressAndTokens = TangemPayUtilities.getCustomerWalletAddressAndAuthorizationTokens(
            customerWalletId: userWalletId.stringValue,
            keysRepository: keysRepository
        )

        authorizationService = TangemPayAPIServiceBuilder().buildTangemPayAuthorizationService(
            customerWalletId: userWalletId.stringValue,
            authorizationTokensRepository: Self.tangemPayAuthorizationTokensRepository,
            tokens: customerWalletAddressAndTokens?.tokens
        )

        customerInfoManagementService = TangemPayCustomerInfoManagementServiceBuilder()
            .buildCustomerInfoManagementService(authorizationTokensHandler: authorizationService)

        remoteStateFetcher = TangemPayEnrollmentStateFetcher(
            customerWalletId: userWalletId.stringValue,
            customerInfoManagementService: customerInfoManagementService
        )

        // No reference cycle here, self is stored as weak
        tangemPayNotificationManager.setupManager(with: self)

        bind()

        guard customerWalletAddressAndTokens != nil else {
            stateSubject.value = .syncNeeded
            return
        }

        refresh()
    }

    @discardableResult
    func refresh() -> Task<Void, Never> {
        runTask { [self] in
            do {
                let remoteState = try await remoteStateFetcher.getEnrollmentState()
                await handleRemoteState(remoteState)
            } catch {
                // failure events handled via corresponding publisher subscription
                VisaLogger.error("Failed to get TangemPay remote state", error: error)
            }
        }
    }

    @discardableResult
    func authorizeWithCustomerWallet() async throws -> TangemPayEnrollmentState {
        try await authorizingInteractor.authorize(
            customerWalletId: customerWalletId,
            authorizationService: authorizationService
        )
        let remoteState = try await remoteStateFetcher.getEnrollmentState()
        await handleRemoteState(remoteState)
        return remoteState
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

    private func handleRemoteState(_ remoteState: TangemPayEnrollmentState) async {
        switch remoteState {
        case .issuingCard:
            guard let customerWalletAddress else {
                stateSubject.value = .syncNeeded
                return
            }
            do {
                try await issueCardIfNeededAndStartStatusPolling(customerWalletAddress: customerWalletAddress)
                stateSubject.value = .issuingCard
            } catch {
                stateSubject.value = .unavailable
            }

        case .enrolled(let customerInfo):
            guard let customerWalletAddress else {
                stateSubject.value = .syncNeeded
                return
            }
            cardIssuingOrderStatusPollingService.cancel()
            TangemPayOrderIdStorage.deleteCardIssuingOrderId(customerWalletId: customerWalletId)
            stateSubject.value = .tangemPayAccount(
                TangemPayAccountBuilder().build(
                    customerWalletAddress: customerWalletAddress,
                    customerInfo: customerInfo,
                    userWalletId: userWalletId,
                    keysRepository: keysRepository,
                    signer: signer,
                    authorizationTokensHandler: authorizationService,
                    customerInfoManagementService: customerInfoManagementService
                )
            )

        case .notEnrolled, .kyc:
            cardIssuingOrderStatusPollingService.cancel()
        }
    }

    private func issueCardIfNeededAndStartStatusPolling(customerWalletAddress: String) async throws {
        let orderId: String

        if let cardIssuingOrderId = TangemPayOrderIdStorage.cardIssuingOrderId(customerWalletId: customerWalletId) {
            orderId = cardIssuingOrderId
        } else {
            orderId = try await customerInfoManagementService.placeOrder(customerWalletAddress: customerWalletAddress).id
            TangemPayOrderIdStorage.saveCardIssuingOrderId(orderId, customerWalletId: customerWalletId)
        }

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
        runTask { [self] in
            stateSubject.value = .syncInProgress
            do {
                try await authorizeWithCustomerWallet()
            } catch {
                VisaLogger.error("Failed to authorize with customer wallet", error: error)
                stateSubject.value = .syncNeeded
            }
        }
    }

    private func bind() {
        Publishers.Merge(
            authorizationService.errorEventPublisher,
            customerInfoManagementService.errorEventPublisher
        )
        .map { event -> TangemPayLocalState in
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

private extension TangemPayManager {
    enum Constants {
        static let cardIssuingOrderPollInterval: TimeInterval = 60
    }
}
