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
            .eraseToAnyPublisher()
    }

    var id: TangemPayAccountId {
        TangemPayAccountId(userWalletId: userWalletId)
    }

    private(set) var customerId: String?

    private var customerWalletId: String {
        userWalletId.stringValue
    }

    private let userWalletId: UserWalletId
    private let keysRepository: KeysRepository
    private let availabilityService: TangemPayAvailabilityService
    private let authorizationService: TangemPayAuthorizationService
    private let customerService: CustomerInfoManagementService
    private let enrollmentStateFetcher: TangemPayEnrollmentStateFetcher
    private let orderStatusPollingService: TangemPayOrderStatusPollingService
    private let orderIdStorage: TangemPayOrderIdStorage
    private let paeraCustomerFlagRepository: TangemPayPaeraCustomerFlagRepository
    private let cachedStateStorage: TangemPayCachedStateStorage
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
        orderIdStorage: TangemPayOrderIdStorage,
        paeraCustomerFlagRepository: TangemPayPaeraCustomerFlagRepository,
        cachedStateStorage: TangemPayCachedStateStorage,
        tangemPayAccountBuilder: TangemPayAccountBuilder
    ) {
        self.userWalletId = userWalletId
        self.keysRepository = keysRepository
        self.availabilityService = availabilityService
        self.authorizationService = authorizationService
        self.customerService = customerService
        self.enrollmentStateFetcher = enrollmentStateFetcher
        self.orderStatusPollingService = orderStatusPollingService
        self.orderIdStorage = orderIdStorage
        self.paeraCustomerFlagRepository = paeraCustomerFlagRepository
        self.cachedStateStorage = cachedStateStorage
        self.tangemPayAccountBuilder = tangemPayAccountBuilder

        bind()

        runTask { [self] in
            await refreshState()
        }
    }

    func authorizeWithCustomerWallet(
        authorizingInteractor: TangemPayAuthorizing,
        pendingDerivations: [PendingDerivation]
    ) async {
        let derivationPaths = PendingDerivationHelper.pendingDerivationPathsKeyedByPublicKeys(pendingDerivations)

        do {
            let authorizingResponse = try await authorizingInteractor.authorize(
                customerWalletId: customerWalletId,
                authorizationService: authorizationService,
                pendingDerivations: derivationPaths
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

        guard let (customerWalletAddress, _) = TangemPayUtilities.getCustomerWalletAddressAndAuthorizationTokens(
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
            case .moyaError, .apiError, .decodingError:
                stateSubject.value = .unavailable
            }
            VisaLogger.error("Failed to get TangemPay enrollment state", error: error)
            return
        }

        let weakReferenceHolder = TangemPayManagerWeakReferenceHolder(tangemPayManager: self)

        switch enrollmentState {
        case .disabled:
            orderStatusPollingService.cancel()
            paeraCustomerFlagRepository.setIsTangemPayDisabled(true, for: customerWalletId)
            stateSubject.value = nil

        case .issuingCard:
            do {
                try await issueCardIfNeededAndStartStatusPolling(customerWalletAddress: customerWalletAddress)
                stateSubject.value = .issuingCard
            } catch {
                stateSubject.value = .unavailable
            }
            Analytics.log(.visaOnboardingVisaKYCPassedAndOrderCreated, analyticsSystems: .all, contextParams: .userWallet(userWalletId))

        case .enrolled(let customerInfo, let productInstance):
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
            stateSubject.value = .tangemPayAccount(account)
            Analytics.log(.visaOnboardingVisaKYCPassedAndOrderCreated, analyticsSystems: .all, contextParams: .userWallet(userWalletId))

        case .kycRequired(let productInstanceExists):
            orderStatusPollingService.cancel()
            stateSubject.value = .kycRequired(weakReferenceHolder)
            if !productInstanceExists {
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
        }
    }

    func syncTokens(
        authorizingInteractor: TangemPayAuthorizing,
        pendingDerivations: [PendingDerivation],
        completion: @escaping () -> Void
    ) {
        runTask { [self] in
            stateSubject.value = .syncInProgress
            await authorizeWithCustomerWallet(authorizingInteractor: authorizingInteractor, pendingDerivations: pendingDerivations)
            completion()
        }
    }

    private func issueCardIfNeededAndStartStatusPolling(customerWalletAddress: String) async throws {
        let orderId = try await issueCardIfNeeded(customerWalletAddress: customerWalletAddress)

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
        static let cardIssuingOrderPollInterval: TimeInterval = 60
    }
}
