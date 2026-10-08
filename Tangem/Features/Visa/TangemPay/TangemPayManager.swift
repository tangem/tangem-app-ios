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

    @Injected(\.tangemPayRecentOperationsStore)
    private var tangemPayRecentOperationsStore: TangemPayRecentOperationsStore

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
    private let residencyStatusStorage: TangemPayResidencyStatusStorage
    private let waitlistService: TangemPayWaitlistService
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
        residencyStatusStorage: TangemPayResidencyStatusStorage,
        waitlistService: TangemPayWaitlistService,
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
        self.residencyStatusStorage = residencyStatusStorage
        self.waitlistService = waitlistService
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
                hideLocally()
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

    func hideAccountFromHome() {
        orderStatusPollingService.cancel()
        hideLocally()
    }

    func beginResidency() {
        residencyStatusStorage.setResidencyStatus(.pending, userWalletId: userWalletId, product: .paymentAccount)
        applyResidencyStatus()
    }

    func completeResidency(_ result: TangemPayResidencyResult) {
        switch result {
        case .eligible:
            residencyStatusStorage.clearResidencyStatus(userWalletId: userWalletId, product: .paymentAccount)
        case .unavailable(let region):
            residencyStatusStorage.setResidencyStatus(.unavailable(region), userWalletId: userWalletId, product: .paymentAccount)
        }

        applyResidencyStatus()
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

        let weakReferenceHolder = makeWeakReferenceHolder()

        switch enrollmentState {
        case .enrolled(let customerInfo):
            let account = makePaymentAccount(customerInfo: customerInfo)
            customerInfoCacheStorage.saveCachedCustomerInfo(
                customerInfo,
                customerWalletId: customerWalletId
            )
            stateSubject.value = .tangemPayAccount(account)
            Analytics.log(.visaOnboardingVisaKYCPassedAndOrderCreated, analyticsSystems: .all, contextParams: .userWallet(userWalletId))

        case .cardDeactivated(let customerInfo):
            let account = makePaymentAccount(customerInfo: customerInfo)
            stateSubject.value = .cardDeactivated(account)

        case .kycRequired:
            orderStatusPollingService.cancel()
            stateSubject.value = makeKYCRequiredState()

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

    func placeCampaignCardIssueOrder(campaignKey: String) async throws(TangemPayCampaignOrderError) {
        guard let (customerWalletAddress, _) = tangemPayAssembly.customerWalletAddressAndSavedTokensResolver.resolve(
            customerWalletId: customerWalletId,
            keysRepository: keysRepository
        ) else {
            throw .missingCustomerWalletAddress
        }

        // A failed lookup must not block enrollment — `findOrders` is not known to answer before KYC —
        // so `try?` falls through to placing the order.
        if (try? await orderResolver.findActiveCardIssueOrder()) != nil {
            await refreshState()
            return
        }

        let offers: TangemPayCustomerOffersResponse
        do {
            offers = try await customerService.getCustomerOffers(deeplinkValue: campaignKey)
        } catch {
            throw .api(error)
        }

        guard let offer = offers.first(where: { $0.type.isCampaignCardIssue }),
              let offerData = offer.data,
              let specificationName = offerData.specificationName else {
            throw .offerUnavailable
        }

        let request = TangemPayPlaceOrderRequest(
            type: offerData.orderType,
            customerWalletAddress: customerWalletAddress,
            specificationName: specificationName,
            deeplinkValue: campaignKey
        )
        let idempotencyKey = TangemPayIdempotencyKey.make(
            customerId ?? customerWalletId,
            offerData.orderType,
            specificationName,
            customerWalletAddress,
            campaignKey
        )

        do {
            _ = try await customerService.placeOrder(request: request, idempotencyKey: idempotencyKey)
        } catch {
            if error.apiErrorCode == TangemPayAPIError.Code.cardIssueOfferNotAvailable {
                throw .offerUnavailable
            }
            throw .api(error)
        }

        await refreshState()
    }

    func cancelTariffPlanPendingTransition() async throws {
        try await customerService.cancelTariffPlanPendingTransition()
        await refreshState()
    }

    private func makeWeakReferenceHolder() -> TangemPayManagerWeakReferenceHolder {
        TangemPayManagerWeakReferenceHolder(tangemPayManager: self, waitlistService: waitlistService)
    }

    private func makeKYCRequiredState() -> TangemPayLocalState {
        let weakReferenceHolder = makeWeakReferenceHolder()

        guard FeatureProvider.isAvailable(.tangemPayChooseCountry) else {
            return .kycRequired(weakReferenceHolder)
        }

        switch residencyStatusStorage.residencyStatus(userWalletId: userWalletId, product: .paymentAccount) {
        case .pending:
            return .residencyRequired(weakReferenceHolder)
        case .unavailable(let region):
            return .regionUnavailable(region, weakReferenceHolder)
        case .none:
            return .kycRequired(weakReferenceHolder)
        }
    }

    private func applyResidencyStatus() {
        switch stateSubject.value {
        case .kycRequired, .residencyRequired, .regionUnavailable:
            stateSubject.value = makeKYCRequiredState()
        default:
            break
        }
    }

    private func hideLocally() {
        paeraCustomerFlagRepository.setIsKYCHidden(true, for: customerWalletId)
        paeraCustomerFlagRepository.setIsPaeraCustomer(false, for: customerWalletId)
        paeraCustomerFlagRepository.setShouldShowGetBanner(false)
        customerInfoCacheStorage.clearCachedCustomerInfo(customerWalletId: customerWalletId)
        cashbackCacheStorage.clearCachedCashbackSummary(customerWalletId: customerWalletId)
        tangemPayRecentOperationsStore.clear(customerWalletId: customerWalletId)
        stateSubject.value = nil
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
                    await self?.loadCashbackSummary(for: account)
                }
            }
            .store(in: &bag)
    }

    private func loadCashbackSummary(for account: TangemPayAccount) async {
        guard !account.isDeactivated else {
            return
        }

        do {
            try await account.loadCashbackSummary()
        } catch {
            VisaLogger.error("Failed to load TangemPay cashback summary", error: error)
        }
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

enum TangemPayCampaignOrderError: Error {
    case missingCustomerWalletAddress
    /// The campaign is over, revoked, or the plan's card limit is reached. Terminal, unlike `api`.
    case offerUnavailable
    case api(TangemPayAPIServiceError)
}
