//
//  TangemPayManager.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemPay
import TangemVisa

final class TangemPayManager {
    var state: TangemPayLocalState {
        stateSubject.value
    }

    var statePublisher: AnyPublisher<TangemPayLocalState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var customerId: String? {
        state.tangemPayAccount?.customerId
    }

    private let customerWalletId: String
    private let keysRepository: KeysRepository
    private let authorizationService: TangemPayAuthorizationService
    private let customerService: CustomerInfoManagementService
    private let enrollmentStateFetcher: TangemPayEnrollmentStateFetcher
    private let orderStatusPollingService: TangemPayOrderStatusPollingService
    private let orderIdStorage: TangemPayOrderIdStorage
    private let paeraCustomerFlagRepository: TangemPayPaeraCustomerFlagRepository
    private let tangemPayAccountBuilder: TangemPayAccountBuilder

    private let stateSubject = CurrentValueSubject<TangemPayLocalState, Never>(.initial)

    private var bag = Set<AnyCancellable>()

    init(
        customerWalletId: String,
        keysRepository: KeysRepository,
        authorizationService: TangemPayAuthorizationService,
        customerService: CustomerInfoManagementService,
        enrollmentStateFetcher: TangemPayEnrollmentStateFetcher,
        orderStatusPollingService: TangemPayOrderStatusPollingService,
        orderIdStorage: TangemPayOrderIdStorage,
        paeraCustomerFlagRepository: TangemPayPaeraCustomerFlagRepository,
        tangemPayAccountBuilder: TangemPayAccountBuilder
    ) {
        self.customerWalletId = customerWalletId
        self.keysRepository = keysRepository
        self.authorizationService = authorizationService
        self.customerService = customerService
        self.enrollmentStateFetcher = enrollmentStateFetcher
        self.orderStatusPollingService = orderStatusPollingService
        self.orderIdStorage = orderIdStorage
        self.paeraCustomerFlagRepository = paeraCustomerFlagRepository
        self.tangemPayAccountBuilder = tangemPayAccountBuilder

        runTask { [self] in
            await refreshState()
        }
    }

    func authorizeWithCustomerWallet(authorizingInteractor: TangemPayAuthorizing) async {
        do {
            let authorizingResponse = try await authorizingInteractor.authorize(
                customerWalletId: customerWalletId,
                authorizationService: authorizationService
            )

            keysRepository.update(derivations: authorizingResponse.derivationResult)
            try authorizationService.saveTokens(tokens: authorizingResponse.tokens)

            paeraCustomerFlagRepository.setIsPaeraCustomer(true, for: customerWalletId)
            paeraCustomerFlagRepository.setIsKYCHidden(false, for: customerWalletId)
        } catch {
            VisaLogger.error("Failed to authorize with customer wallet", error: error)
            stateSubject.value = .unavailable
            return
        }

        await refreshState()
    }

    func launchKYC(onDidDismiss: @escaping () -> Void) async throws {
        try await KYCService.start(
            getToken: customerService.loadKYCAccessToken,
            onDidDismiss: onDidDismiss
        )
        Analytics.log(.visaOnboardingVisaKYCFlowOpened)
    }

    func cancelKYC(onFinish: @escaping (Bool) -> Void) {
        runTask { [self] in
            do {
                try await customerService.cancelKYC()
                paeraCustomerFlagRepository.setIsKYCHidden(true, for: customerWalletId)
                paeraCustomerFlagRepository.setIsPaeraCustomer(false, for: customerWalletId)
                paeraCustomerFlagRepository.setShouldShowGetBanner(false)
                stateSubject.value = .initial
                onFinish(true)
            } catch {
                VisaLogger.error("Failed to cancel KYC", error: error)
                onFinish(false)
            }
        }
    }

    func refreshState() async {
        guard !paeraCustomerFlagRepository.isKYCHidden(customerWalletId: customerWalletId) else {
            return
        }

        if case .initial = stateSubject.value {
            stateSubject.value = .loading
        }

        let customerWalletAddress = TangemPayUtilities.getCustomerWalletAddressAndAuthorizationTokens(
            customerWalletId: customerWalletId,
            keysRepository: keysRepository
        )?.customerWalletAddress

        let enrollmentState: TangemPayEnrollmentState
        do {
            enrollmentState = try await enrollmentStateFetcher.getEnrollmentState(customerWalletAddress: customerWalletAddress)
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
            let account = tangemPayAccountBuilder.makeTangemPayAccount(
                customerInfo: customerInfo,
                productInstance: productInstance
            )
            runTask {
                await account.loadBalance()
            }
            stateSubject.value = .tangemPayAccount(account)

        case .notEnrolled:
            orderStatusPollingService.cancel()
            stateSubject.value = .initial

        case .kycRequired:
            orderStatusPollingService.cancel()
            stateSubject.value = .kycRequired

        case .kycDeclined:
            orderStatusPollingService.cancel()
            stateSubject.value = .kycDeclined
        }
    }

    func syncTokens(authorizingInteractor: TangemPayAuthorizing) {
        runTask { [self] in
            stateSubject.value = .syncInProgress
            await authorizeWithCustomerWallet(authorizingInteractor: authorizingInteractor)
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

    private func bind() {
        stateSubject
            .compactMap(\.tangemPayAccount)
            .flatMap(\.syncNeededSignalPublisher)
            .mapToValue(.syncNeeded)
            .sink(receiveValue: stateSubject.send)
            .store(in: &bag)

        stateSubject
            .compactMap(\.tangemPayAccount)
            .flatMap(\.unavailableSignalPublisher)
            .mapToValue(.unavailable)
            .sink(receiveValue: stateSubject.send)
            .store(in: &bag)
    }
}

private extension TangemPayManager {
    enum Constants {
        static let cardIssuingOrderPollInterval: TimeInterval = 60
    }
}
