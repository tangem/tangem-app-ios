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

struct TangemPayBuilder {
    let userWalletId: UserWalletId
    let keysRepository: KeysRepository
    let signer: any TangemSigner

    func buildTangemPayManager() {
        let customerWalletAddressAndTokens = TangemPayUtilities.getCustomerWalletAddressAndAuthorizationTokens(
            customerWalletId: userWalletId.stringValue,
            keysRepository: keysRepository
        )

        let authorizationService = TangemPayAPIServiceBuilder().buildTangemPayAuthorizationService(
            customerWalletId: userWalletId.stringValue,
            tokens: customerWalletAddressAndTokens?.tokens
        )

        let customerInfoManagementService = TangemPayCustomerInfoManagementServiceBuilder()
            .buildCustomerInfoManagementService(authorizationTokensHandler: authorizationService)

        let remoteStateFetcher = TangemPayEnrollmentStateFetcher(
            customerWalletId: userWalletId.stringValue,
            customerInfoManagementService: customerInfoManagementService
        )
    }

    func buildTangemPayNotificationManager(
        tangemPayManager: TangemPayManager
    ) -> TangemPayNotificationManager {
        let notificationManager = TangemPayNotificationManager(
            paeraCustomerStatePublisher: tangemPayManager.statePublisher
        )
        notificationManager.setupManager(with: tangemPayManager)
        return notificationManager
    }

    func buildTangemPayAccount(
        customerWalletAddress: String,
        customerInfo: VisaCustomerInfoResponse,
        customerInfoManagementService: CustomerInfoManagementService
    ) -> TangemPayAccount {
        let tokenBalancesRepository = CommonTokenBalancesRepository(userWalletId: userWalletId)

        let balancesService = CommonTangemPayBalanceService(
            customerInfoManagementService: customerInfoManagementService,
            tokenBalancesRepository: tokenBalancesRepository
        )

        let withdrawTransactionService = CommonTangemPayWithdrawTransactionService(
            customerInfoManagementService: customerInfoManagementService,
            fiatItem: TangemPayUtilities.fiatItem,
            signer: signer
        )

        return TangemPayAccount(
            customerWalletId: userWalletId.stringValue,
            customerWalletAddress: customerWalletAddress,
            customerInfo: customerInfo,
            keysRepository: keysRepository,
            customerInfoManagementService: customerInfoManagementService,
            balancesService: balancesService,
            withdrawTransactionService: withdrawTransactionService
        )
    }
}

final class TangemPayManager {
    let tangemPayNotificationManager: TangemPayNotificationManager

    var state: TangemPayLocalState {
        stateSubject.value
    }

    var statePublisher: AnyPublisher<TangemPayLocalState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

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

        guard customerWalletAddressAndTokens != nil else {
            stateSubject.value = .syncNeeded
            return
        }

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

    func refreshState() async {
        let enrollmentState: TangemPayEnrollmentState
        do {
            enrollmentState = try await remoteStateFetcher.getEnrollmentState()
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
