//
//  TangemPayManager.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import UIKit
import TangemFoundation
import TangemPay
import TangemVisa
import TangemSdk

final class TangemPayManager: TangemPayAccountModel {
    var state: TangemPayLocalState? {
        stateSubject.value
    }

    var statePublisher: AnyPublisher<TangemPayLocalState, Never> {
        stateSubject
            .compactMap(\.self)
            .eraseToAnyPublisher()
    }

    var isPaeraCustomerPublisher: AnyPublisher<Bool, Never> {
        stateSubject
            .map { $0 != nil }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var id: TangemPayAccountId {
        TangemPayAccountId(userWalletId: userWalletId)
    }

    private(set) var customerId: String?

    var lastKnownTangemPayAccount: TangemPayAccount? {
        guard
            let cached = customerInfoCacheStorage.cachedCustomerInfo(customerWalletId: customerWalletId),
            let productInstance = cached.productInstance
        else {
            return nil
        }
        return tangemPayAccountBuilder.makeTangemPayAccount(
            customerInfo: cached,
            productInstance: productInstance,
            account: self
        )
    }

    private var customerWalletId: String {
        userWalletId.stringValue
    }

    private var multipleCardsEnabled: Bool {
        FeatureProvider.isAvailable(.tangemPayMultipleCards)
    }

    @Injected(\.tangemPayAssembly)
    private var tangemPayAssembly: TangemPayAssembly

    private let userWalletId: UserWalletId
    private let keysRepository: KeysRepository
    private let availabilityService: TangemPayAvailabilityService
    private let authorizationService: TangemPayAuthorizationService
    private let customerService: CustomerInfoManagementService
    private let enrollmentStateFetcher: TangemPayEnrollmentStateFetcher
    private let orderStatusPollingService: TangemPayOrderStatusPollingService
    private let orderResolver: TangemPayOrderResolver
    private let orderIdStorage: TangemPayOrderIdStorage
    private let paeraCustomerFlagRepository: TangemPayPaeraCustomerFlagRepository
    private let cachedStateStorage: TangemPayCachedStateStorage
    private let customerInfoCacheStorage: TangemPayCustomerInfoCacheStorage
    private let tangemPayAccountBuilder: TangemPayAccountBuilder

    private let stateSubject = CurrentValueSubject<TangemPayLocalState?, Never>(nil)

    private var bag = Set<AnyCancellable>()

    init(
        userWalletId: UserWalletId,
        keysRepository: KeysRepository,
        availabilityService: TangemPayAvailabilityService,
        authorizationService: TangemPayAuthorizationService,
        customerService: CustomerInfoManagementService,
        enrollmentStateFetcher: TangemPayEnrollmentStateFetcher,
        orderStatusPollingService: TangemPayOrderStatusPollingService,
        orderResolver: TangemPayOrderResolver,
        orderIdStorage: TangemPayOrderIdStorage,
        paeraCustomerFlagRepository: TangemPayPaeraCustomerFlagRepository,
        cachedStateStorage: TangemPayCachedStateStorage,
        customerInfoCacheStorage: TangemPayCustomerInfoCacheStorage,
        tangemPayAccountBuilder: TangemPayAccountBuilder
    ) {
        self.userWalletId = userWalletId
        self.keysRepository = keysRepository
        self.availabilityService = availabilityService
        self.authorizationService = authorizationService
        self.customerService = customerService
        self.enrollmentStateFetcher = enrollmentStateFetcher
        self.orderStatusPollingService = orderStatusPollingService
        self.orderResolver = orderResolver
        self.orderIdStorage = orderIdStorage
        self.paeraCustomerFlagRepository = paeraCustomerFlagRepository
        self.cachedStateStorage = cachedStateStorage
        self.customerInfoCacheStorage = customerInfoCacheStorage
        self.tangemPayAccountBuilder = tangemPayAccountBuilder

        bind()
        observeAppLifecycle()

        if let cached = lastKnownTangemPayAccount {
            stateSubject.value = .tangemPayAccount(cached)
            runTask { [cached] in
                await cached.loadBalance()
            }
        }

        runTask { [self] in
            await refreshState()
        }
    }

    func authorizeWithCustomerWallet(
        authorizingInteractor: TangemPayAuthorizing
    ) async {
        do {
            let authorizingResponse = try await authorizingInteractor.authorize(
                customerWalletId: customerWalletId,
                authorizationService: authorizationService
            )

            keysRepository.update(derivations: authorizingResponse.derivationResult)
            try? authorizationService.saveTokens(tokens: authorizingResponse.tokens)

            paeraCustomerFlagRepository.setIsPaeraCustomer(true, for: customerWalletId)
            paeraCustomerFlagRepository.setIsKYCHidden(false, for: customerWalletId)
        } catch {
            keysRepository.update(derivations: error.derivationResult)
            VisaLogger.error("Failed to authorize with customer wallet", error: error.underlyingError)
            stateSubject.value = .unavailable
            return
        }

        await refreshState()
    }

    func launchKYC(onDidDismiss: (() async -> Void)? = nil) async throws {
        try await KYCService.start(
            getToken: customerService.loadKYCAccessToken,
            onDidDismiss: { [weak self] in
                await self?.refreshState()
                await onDidDismiss?()
            }
        )
        Analytics.log(.visaOnboardingVisaKYCFlowOpened, analyticsSystems: .all, contextParams: .userWallet(userWalletId))
    }

    func cancelKYC(onFinish: @escaping (Bool) -> Void) {
        runTask { [self] in
            do {
                try await customerService.cancelKYC()
                paeraCustomerFlagRepository.setIsKYCHidden(true, for: customerWalletId)
                paeraCustomerFlagRepository.setIsPaeraCustomer(false, for: customerWalletId)
                paeraCustomerFlagRepository.setShouldShowGetBanner(false)
                customerInfoCacheStorage.clearCachedCustomerInfo(customerWalletId: customerWalletId)
                stateSubject.value = nil
                onFinish(true)
            } catch {
                VisaLogger.error("Failed to cancel KYC", error: error)
                onFinish(false)
            }
        }
        Analytics.log(.visaOnboardingVisaKYCCanceled, contextParams: .userWallet(userWalletId))
    }

    func refreshState() async {
        guard await availabilityService.isPaeraCustomer(customerWalletId: customerWalletId) else {
            orderStatusPollingService.cancel()
            stateSubject.value = nil
            return
        }

        if stateSubject.value == nil {
            stateSubject.value = .loading
        }

        guard let (customerWalletAddress, _) = tangemPayAssembly.customerWalletAddressAndSavedTokensResolver.resolve(
            customerWalletId: customerWalletId,
            keysRepository: keysRepository
        ) else {
            stateSubject.value = .syncNeeded
            return
        }

        let enrollmentState: TangemPayEnrollmentState
        do {
            (enrollmentState, customerId) = try await enrollmentStateFetcher.getEnrollmentState()
        } catch {
            switch error {
            case .unauthorized:
                stateSubject.value = .syncNeeded
            case .moyaError, .apiError, .decodingError, .serverError:
                stateSubject.value = .unavailable
            }
            VisaLogger.error("Failed to get TangemPay enrollment state", error: error)
            return
        }

        let weakReferenceHolder = TangemPayManagerWeakReferenceHolder(tangemPayManager: self)

        switch enrollmentState {
        case .issuingCard:
            do {
                try await resumeOrIssueCardAndStartStatusPolling(customerWalletAddress: customerWalletAddress)
                stateSubject.value = .issuingCard
            } catch {
                stateSubject.value = .unavailable
            }
            Analytics.log(.visaOnboardingVisaKYCPassedAndOrderCreated, analyticsSystems: .all, contextParams: .userWallet(userWalletId))

        case .enrolled(let customerInfo, let productInstance):
            let account = makePaymentAccount(
                customerInfo: customerInfo,
                productInstance: productInstance
            )
            customerInfoCacheStorage.saveCachedCustomerInfo(
                customerInfo,
                customerWalletId: customerWalletId
            )
            stateSubject.value = .tangemPayAccount(account)
            Analytics.log(.visaOnboardingVisaKYCPassedAndOrderCreated, analyticsSystems: .all, contextParams: .userWallet(userWalletId))

        case .cardDeactivated(let customerInfo, let productInstance):
            let account = makePaymentAccount(
                customerInfo: customerInfo,
                productInstance: productInstance
            )
            stateSubject.value = .cardDeactivated(account)

        case .kycRequired(let productInstanceExists):
            orderStatusPollingService.cancel()
            stateSubject.value = .kycRequired(weakReferenceHolder)
            if !productInstanceExists, !FeatureProvider.isAvailable(.tangemPayTiers) {
                do {
                    try await issueCardIfNeeded(customerWalletAddress: customerWalletAddress)
                } catch {
                    stateSubject.value = .unavailable
                }
            }

        case .kycDeclined:
            orderStatusPollingService.cancel()
            stateSubject.value = .kycDeclined(weakReferenceHolder)
            Analytics.log(.visaOnboardingVisaKYCRejected, contextParams: .userWallet(userWalletId))

        case .planSelectNeeded:
            stateSubject.value = .planSelectNeeded(tariffPlanSelector: weakReferenceHolder)
        }
    }

    func renewSession(
        authorizingInteractor: TangemPayAuthorizing,
        completion: @escaping () -> Void
    ) {
        runTask { [self] in
            stateSubject.value = .syncInProgress
            await authorizeWithCustomerWallet(authorizingInteractor: authorizingInteractor)
            completion()
        }
    }

    func getTariffPlanTransitions() async throws -> TangemPayTariffPlanTransitionsResponse {
        try await customerService.getTariffPlanTransitions()
    }

    func selectTariffPlan(
        targetTariffPlanId: String,
        transitionType: TangemPayTariffPlanTransition.TransitionType
    ) async throws {
        guard let (customerWalletAddress, _) = tangemPayAssembly.customerWalletAddressAndSavedTokensResolver.resolve(
            customerWalletId: customerWalletId,
            keysRepository: keysRepository
        ) else {
            throw TangemPayManagerError.missingCustomerWalletAddress
        }

        let request = TangemPayPlaceOrderRequest(
            targetTariffPlanId: targetTariffPlanId,
            transitionType: transitionType.rawValue,
            customerWalletAddress: customerWalletAddress
        )
        let idempotencyKey = TangemPayIdempotencyKey.make(
            customerId ?? customerWalletId,
            TangemPayOrderType.tariffPlanTransition.rawValue,
            targetTariffPlanId,
            transitionType.rawValue
        )

        let order = try await customerService.placeOrder(request: request, idempotencyKey: idempotencyKey)
        orderIdStorage.saveCardIssuingOrderId(order.id, customerWalletId: customerWalletId)
        stateSubject.value = .issuingCard
        startCardIssuingOrderPolling(orderId: order.id)
    }

    private func resumeOrIssueCardAndStartStatusPolling(customerWalletAddress: String) async throws {
        guard FeatureProvider.isAvailable(.tangemPayTiers) else {
            // Legacy flow: resume the stored order or auto-issue the card.
            try await issueCardIfNeededAndStartStatusPolling(customerWalletAddress: customerWalletAddress)
            return
        }

        // Tiers flow: the order is created only on plan selection, never here. Resume the in-flight
        // order — stored id first, then recovery (e.g. after reinstall or a backend-issued card).
        if let storedOrderId = orderIdStorage.cardIssuingOrderId(customerWalletId: customerWalletId) {
            startCardIssuingOrderPolling(orderId: storedOrderId)
        } else if let order = try await orderResolver.findActiveTariffPlanTransitionOrder() {
            orderIdStorage.saveCardIssuingOrderId(order.id, customerWalletId: customerWalletId)
            startCardIssuingOrderPolling(orderId: order.id)
        }
    }

    private func issueCardIfNeededAndStartStatusPolling(customerWalletAddress: String) async throws {
        let orderId = try await issueCardIfNeeded(customerWalletAddress: customerWalletAddress)
        startCardIssuingOrderPolling(orderId: orderId)
    }

    private func startCardIssuingOrderPolling(orderId: String) {
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

    @discardableResult
    private func issueCardIfNeeded(customerWalletAddress: String) async throws(TangemPayAPIServiceError) -> String {
        if let cardIssuingOrderId = orderIdStorage.cardIssuingOrderId(customerWalletId: customerWalletId) {
            return cardIssuingOrderId
        } else {
            let orderId = try await customerService.placeOrder(customerWalletAddress: customerWalletAddress).id
            orderIdStorage.saveCardIssuingOrderId(orderId, customerWalletId: customerWalletId)
            return orderId
        }
    }

    private func makePaymentAccount(
        customerInfo: VisaCustomerInfoResponse,
        productInstance: VisaCustomerInfoResponse.ProductInstance
    ) -> TangemPayAccount {
        orderStatusPollingService.cancel()
        orderIdStorage.deleteCardIssuingOrderId(customerWalletId: customerWalletId)
        let account = tangemPayAccountBuilder.makeTangemPayAccount(
            customerInfo: customerInfo,
            productInstance: productInstance,
            account: self
        )
        runTask {
            await account.loadBalance()
        }
        if multipleCardsEnabled {
            runTask {
                await account.resumeAdditionalCardIssuePolling()
            }
        }
        return account
    }

    private func observeAppLifecycle() {
        guard multipleCardsEnabled else { return }

        NotificationCenter.default
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                runTask { [weak self] in
                    guard let account = self?.state?.tangemPayAccount else { return }
                    await account.loadCustomerInfo()
                    await account.loadOffers()
                    await account.resumeAdditionalCardIssuePolling()
                }
            }
            .store(in: &bag)
    }

    private func bind() {
        stateSubject
            .compactMap(\.?.tangemPayAccount)
            .flatMapLatest(\.syncNeededSignalPublisher)
            .mapToValue(.syncNeeded)
            .sink(receiveValue: stateSubject.send)
            .store(in: &bag)

        stateSubject
            .compactMap(\.?.tangemPayAccount)
            .flatMapLatest(\.unavailableSignalPublisher)
            .mapToValue(.unavailable)
            .sink(receiveValue: stateSubject.send)
            .store(in: &bag)

        stateSubject
            .compactMap(\.?.cachedLocalState)
            .withWeakCaptureOf(self)
            .sink { manager, cachedState in
                manager.cachedStateStorage.saveCachedLocalState(
                    cachedState,
                    customerWalletId: manager.customerWalletId
                )
            }
            .store(in: &bag)
    }
}

private extension TangemPayManager {
    enum Constants {
        static let cardIssuingOrderPollInterval: TimeInterval = 5
    }
}

enum TangemPayManagerError: Error {
    case missingCustomerWalletAddress
    case managerDeallocated
}
