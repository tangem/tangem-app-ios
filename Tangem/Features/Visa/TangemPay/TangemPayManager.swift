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

final class TangemPayManager: TangemPayAccountModel, TangemPayAccountRemoving {
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
            !cached.productInstances.isEmpty
        else {
            return nil
        }
        return tangemPayAccountBuilder.makeTangemPayAccount(
            customerInfo: cached,
            account: self,
            accountRemover: self
        )
    }

    private var customerWalletId: String {
        userWalletId.stringValue
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
    private let cashbackCacheStorage: TangemPayCashbackCacheStorage
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
        cashbackCacheStorage: TangemPayCashbackCacheStorage,
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
        self.cashbackCacheStorage = cashbackCacheStorage
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
        authorizingInteractor: TangemPayAuthorizing,
        showSyncInProgress: Bool
    ) async throws(TangemPayAuthorizationError) {
        let stateBeforeAuthorization = stateSubject.value

        if showSyncInProgress {
            stateSubject.value = .syncInProgress
        }

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
            stateSubject.value = stateBeforeAuthorization
            throw error
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
                cashbackCacheStorage.clearCachedCashbackSummary(customerWalletId: customerWalletId)
                stateSubject.value = nil
                onFinish(true)
            } catch {
                VisaLogger.error("Failed to cancel KYC", error: error)
                onFinish(false)
            }
        }
        Analytics.log(.visaOnboardingVisaKYCCanceled, contextParams: .userWallet(userWalletId))
    }

    func removeAccount(onFinish: @escaping (Bool) -> Void) {
        cancelKYC(onFinish: onFinish)
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

        guard tangemPayAssembly.customerWalletAddressAndSavedTokensResolver.resolve(
            customerWalletId: customerWalletId,
            keysRepository: keysRepository
        ) != nil else {
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
        case .enrolled(let customerInfo, _):
            let account = makePaymentAccount(customerInfo: customerInfo)
            customerInfoCacheStorage.saveCachedCustomerInfo(
                customerInfo,
                customerWalletId: customerWalletId
            )
            stateSubject.value = .tangemPayAccount(account)
            Analytics.log(.visaOnboardingVisaKYCPassedAndOrderCreated, analyticsSystems: .all, contextParams: .userWallet(userWalletId))

        case .cardDeactivated(let customerInfo, _):
            let account = makePaymentAccount(customerInfo: customerInfo)
            stateSubject.value = .cardDeactivated(account)

        case .kycRequired:
            orderStatusPollingService.cancel()
            stateSubject.value = .kycRequired(weakReferenceHolder)

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
            try? await authorizeWithCustomerWallet(
                authorizingInteractor: authorizingInteractor,
                showSyncInProgress: true
            )
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

        _ = try await customerService.placeOrder(request: request, idempotencyKey: idempotencyKey)

        await refreshState()
    }

    func cancelTariffPlanPendingTransition() async throws {
        try await customerService.cancelTariffPlanPendingTransition()
        await refreshState()
    }

    private func makePaymentAccount(
        customerInfo: VisaCustomerInfoResponse
    ) -> TangemPayAccount {
        orderStatusPollingService.cancel()
        orderIdStorage.deleteCardIssuingOrderId(customerWalletId: customerWalletId)
        let account = tangemPayAccountBuilder.makeTangemPayAccount(
            customerInfo: customerInfo,
            account: self,
            accountRemover: self
        )
        runTask {
            await account.loadBalance()
        }
        runTask {
            await account.resumeActiveIssueOrderPolling()
        }
        runTask {
            await account.checkFailedToIssueState()
        }

        return account
    }

    private func observeAppLifecycle() {
        NotificationCenter.default
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                runTask { [weak self] in
                    guard let account = self?.state?.tangemPayAccount else { return }
                    await account.loadCustomerInfo()
                    await account.loadOffers()
                    await account.resumeActiveIssueOrderPolling()
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
            .compactMap(\.?.tangemPayAccount)
            .flatMapLatest { account in
                account.firstCardIssueFailedSignalPublisher.mapToValue(account)
            }
            .withWeakCaptureOf(self)
            .sink { manager, account in
                manager.stateSubject.value = .failedToIssueCard(account)
            }
            .store(in: &bag)

        stateSubject
            .compactMap(\.?.tangemPayAccount)
            .flatMapLatest { account in
                account.cardIssueCompletedSignal.mapToValue(account)
            }
            .withWeakCaptureOf(self)
            .sink { manager, account in
                manager.stateSubject.value = .tangemPayAccount(account)
            }
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

enum TangemPayManagerError: Error {
    case missingCustomerWalletAddress
    case managerDeallocated
}
