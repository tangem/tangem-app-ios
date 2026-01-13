//
//  TangemPayManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemPay
import TangemVisa

final class TangemPayManager {
    let tangemPayNotificationManager: TangemPayNotificationManager

    var state: TangemPayLocalState {
        stateSubject.value
    }

    var statePublisher: AnyPublisher<TangemPayLocalState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    private let customerWalletId: String
    private let authorizingInteractor: TangemPayAuthorizing
    private let authorizationService: TangemPayAuthorizationService
    private let customerService: TangemPayCustomerService
    private let enrollmentStateFetcher: TangemPayEnrollmentStateFetcher
    private let orderStatusPollingService: TangemPayOrderStatusPollingService
    private let orderIdStorage: TangemPayOrderIdStorage

    private let tangemPayBuilder: TangemPayBuilder

    private let stateSubject = CurrentValueSubject<TangemPayLocalState, Never>(.initial)

    private var bag = Set<AnyCancellable>()

    init(
        customerWalletId: String,
        authorizingInteractor: TangemPayAuthorizing,
        authorizationService: TangemPayAuthorizationService,
        customerService: TangemPayCustomerService,
        enrollmentStateFetcher: TangemPayEnrollmentStateFetcher,
        orderStatusPollingService: TangemPayOrderStatusPollingService,
        orderIdStorage: TangemPayOrderIdStorage,
        tangemPayBuilder: TangemPayBuilder
    ) {
        self.customerWalletId = customerWalletId
        self.authorizingInteractor = authorizingInteractor
        self.authorizationService = authorizationService
        self.customerService = customerService
        self.enrollmentStateFetcher = enrollmentStateFetcher
        self.orderStatusPollingService = orderStatusPollingService
        self.orderIdStorage = orderIdStorage
        self.tangemPayBuilder = tangemPayBuilder

        tangemPayNotificationManager = TangemPayNotificationManager(
            paeraCustomerStatePublisher: stateSubject.eraseToAnyPublisher()
        )

        // No reference cycle here, self is stored as weak
        tangemPayNotificationManager.setupManager(with: self)

        runTask { [self] in
            await refreshState()
        }
    }

    func authorizeWithCustomerWallet() async {
        do {
            try await authorizingInteractor.authorize(
                customerWalletId: customerWalletId,
                authorizationService: authorizationService
            )
        } catch {
            VisaLogger.error("Failed to authorize with customer wallet", error: error)
            stateSubject.value = .syncNeeded
            return
        }

        await refreshState()
    }

    func launchKYC(onDidDismiss: @escaping () -> Void) async throws {
        try await TangemPayKYCService.start(
            getToken: customerService.loadKYCAccessToken,
            onDidDismiss: onDidDismiss
        )
        Analytics.log(.visaOnboardingVisaKYCFlowOpened)
    }

    func cancelKYC(onFinish: @escaping (Bool) -> Void) {
        runTask { [self] in
            do {
                try await customerService.cancelKYC()
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

    func refreshState() async {
        let enrollmentState: TangemPayEnrollmentState
        do {
            enrollmentState = try await enrollmentStateFetcher.getEnrollmentState()
        } catch {
            switch error {
            case .unauthorized:
                stateSubject.value = .syncNeeded
            case .moyaError, .apiError, .decodingError:
                stateSubject.value = .unavailable
            }
            VisaLogger.error("Failed to get TangemPay enrollment state", error: error)
            return
        }

        switch enrollmentState {
        case .issuingCard(let customerWalletAddress):
            do {
                try await issueCardIfNeededAndStartStatusPolling(customerWalletAddress: customerWalletAddress)
                stateSubject.value = .issuingCard
            } catch {
                stateSubject.value = .unavailable
            }

        case .enrolled(let customerInfo, let productInstance):
            orderStatusPollingService.cancel()
            orderIdStorage.deleteCardIssuingOrderId(customerWalletId: customerWalletId)
            stateSubject.value = .tangemPayAccount(
                tangemPayBuilder.buildTangemPayAccount(customerInfo: customerInfo, productInstance: productInstance)
            )

        case .notEnrolled, .kyc:
            orderStatusPollingService.cancel()
        }
    }

    private func issueCardIfNeededAndStartStatusPolling(customerWalletAddress: String) async throws {
        let orderId: String

        if let cardIssuingOrderId = orderIdStorage.cardIssuingOrderId(customerWalletId: customerWalletId) {
            orderId = cardIssuingOrderId
        } else {
            orderId = try await customerService.placeOrder(customerWalletAddress: customerWalletAddress).id
            orderIdStorage.saveCardIssuingOrderId(orderId, customerWalletId: customerWalletId)
        }

        orderStatusPollingService.startOrderStatusPolling(
            orderId: orderId,
            interval: Constants.cardIssuingOrderPollInterval,
            onCompleted: { [weak self] in
                runTask {
                    await self?.refreshState()
                }
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
            await authorizeWithCustomerWallet()
        }
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
