//
//  VirtualAccountManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemPay
import TangemVisa

final class VirtualAccountManager: VirtualAccountModel {
    var state: VirtualAccountLocalState? {
        stateSubject.value
    }

    var statePublisher: AnyPublisher<VirtualAccountLocalState, Never> {
        stateSubject
            .compactMap(\.self)
            .eraseToAnyPublisher()
    }

    var isVirtualAccountCustomerPublisher: AnyPublisher<Bool, Never> {
        stateSubject
            .map { $0 != nil }
            .eraseToAnyPublisher()
    }

    var id: PaymentAccountId {
        .virtualAccount(userWalletId: userWalletId)
    }

    private(set) var customerId: String?

    private var customerWalletId: String {
        userWalletId.stringValue
    }

    private let userWalletId: UserWalletId
    private let keysRepository: KeysRepository
    private let availabilityService: PaymentAccountAvailabilityService
    private let authorizationService: PaymentAccountAuthorizationService
    private let customerService: CustomerInfoManagementService
    private let enrollmentStateFetcher: PaymentAccountEnrollmentStateFetcher
    private let orderStatusPollingService: PaymentAccountOrderStatusPollingService
    private let orderIdStorage: VirtualAccountOrderIdStorage
    private let paeraCustomerFlagRepository: TangemPayPaeraCustomerFlagRepository
    private let cachedStateStorage: VirtualAccountCachedStateStorage
    private let paymentWalletFlagStorage: PaymentWalletFlagStorage

    private let stateSubject = CurrentValueSubject<VirtualAccountLocalState?, Never>(nil)

    private var bag = Set<AnyCancellable>()

    init(
        userWalletId: UserWalletId,
        keysRepository: KeysRepository,
        availabilityService: PaymentAccountAvailabilityService,
        authorizationService: PaymentAccountAuthorizationService,
        customerService: CustomerInfoManagementService,
        enrollmentStateFetcher: PaymentAccountEnrollmentStateFetcher,
        orderStatusPollingService: PaymentAccountOrderStatusPollingService,
        orderIdStorage: VirtualAccountOrderIdStorage,
        paeraCustomerFlagRepository: TangemPayPaeraCustomerFlagRepository,
        cachedStateStorage: VirtualAccountCachedStateStorage,
        paymentWalletFlagStorage: PaymentWalletFlagStorage
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
        self.paymentWalletFlagStorage = paymentWalletFlagStorage

        bind()

        runTask { [self] in
            await refreshState()
        }
    }

    func authorizeWithCustomerWallet(authorizingInteractor: PaymentAccountAuthorizing) async {
        do {
            let authorizingResponse = try await authorizingInteractor.authorize(
                customerWalletId: customerWalletId,
                authorizationService: authorizationService
            )

            keysRepository.update(derivations: authorizingResponse.derivationResult)
            try authorizationService.saveTokens(tokens: authorizingResponse.tokens)

            paymentWalletFlagStorage.setPaymentWalletDerived(true, for: customerWalletId)
        } catch {
            VisaLogger.error("Failed to authorize VA with customer wallet", error: error)
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
    }

    func cancelKYC(onFinish: @escaping (Bool) -> Void) {
        runTask { [self] in
            do {
                try await customerService.cancelKYC()
                paeraCustomerFlagRepository.setIsKYCHidden(true, for: customerWalletId)
                stateSubject.value = nil
                onFinish(true)
            } catch {
                VisaLogger.error("Failed to cancel VA KYC", error: error)
                onFinish(false)
            }
        }
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

        let hasDerivedWallet = VirtualAccountUtilities.hasDerivedWallet(in: keysRepository)
        if hasDerivedWallet, !paymentWalletFlagStorage.isPaymentWalletDerived(customerWalletId: customerWalletId) {
            stateSubject.value = .userCreatedWalletBlocked
            return
        }

        guard let (customerWalletAddress, _) = TangemPayUtilities.getCustomerWalletAddressAndAuthorizationTokens(
            customerWalletId: customerWalletId,
            keysRepository: keysRepository
        ) else {
            stateSubject.value = .syncNeeded
            return
        }

        let enrollmentState: PaymentAccountEnrollmentState
        do {
            (enrollmentState, customerId) = try await enrollmentStateFetcher.getEnrollmentState()
        } catch {
            switch error {
            case .unauthorized:
                stateSubject.value = .syncNeeded
            case .moyaError, .apiError, .decodingError:
                stateSubject.value = .unavailable
            }
            VisaLogger.error("Failed to get VA enrollment state", error: error)
            return
        }

        let weakReferenceHolder = VirtualAccountManagerWeakReferenceHolder(virtualAccountManager: self)

        switch enrollmentState {
        case .kycRequired:
            do {
                try await placeOrderIfNeeded(customerWalletAddress: customerWalletAddress)
            } catch {
                VisaLogger.error("Failed to place VA order", error: error)
                stateSubject.value = .unavailable
                return
            }
            orderStatusPollingService.cancel()
            stateSubject.value = .kycRequired(weakReferenceHolder)

        case .kycDeclined:
            orderStatusPollingService.cancel()
            stateSubject.value = .kycDeclined(weakReferenceHolder)

        case .issuingCard:
            startProvisioningPolling()
            stateSubject.value = .provisioning

        case .enrolled:
            orderStatusPollingService.cancel()
            orderIdStorage.deleteVAOnboarding(customerWalletId: customerWalletId)
            stateSubject.value = .active(VirtualAccountActiveState(customerId: customerId ?? ""))
        }
    }

    func syncTokens(
        authorizingInteractor: PaymentAccountAuthorizing,
        completion: @escaping () -> Void
    ) {
        runTask { [self] in
            stateSubject.value = .syncInProgress
            await authorizeWithCustomerWallet(authorizingInteractor: authorizingInteractor)
            completion()
        }
    }

    // MARK: - Private

    private func placeOrderIfNeeded(customerWalletAddress: String) async throws {
        if orderIdStorage.vaOnboardingOrderId(customerWalletId: customerWalletId) != nil {
            return
        }

//        guard let walletPublicKey = VirtualAccountUtilities.getKey(from: keysRepository) else {
//            return
//        }

        let message = "I hereby declare that I am the address owner."
        // [REDACTED_TODO_COMMENT]
        //        **Формат:**
        //        - hex string с префиксом 0x
        //        - 65‑байтная ECDSA подпись (r,s,v), как возвращает текущий Tangem SDK signing метод
        let signature = ""

        let request = VirtualAccountPlaceOrderRequest(
            type: "virtual_account_issue",
            productionSpecificationName: "Monerium",
            customerId: customerId ?? "",
            linkAddress: customerWalletAddress,
            linkNetwork: "polygon",
            linkAddressMessage: message,
            linkAddressSignature: signature
        )

        let orderResponse = try await customerService.placeVirtualAccountOrder(request: request)
        orderIdStorage.saveVAOnboarding(
            orderId: orderResponse.id,
            walletId: customerWalletAddress,
            customerWalletId: customerWalletId
        )
    }

    private func startProvisioningPolling() {
        guard let orderId = orderIdStorage.vaOnboardingOrderId(customerWalletId: customerWalletId) else {
            stateSubject.value = .failedToProvision
            return
        }

        orderStatusPollingService.startOrderStatusPolling(
            orderId: orderId,
            interval: Constants.provisioningOrderPollInterval,
            onCompleted: { [weak self] in
                runTask {
                    await self?.refreshState()
                }
            },
            onCanceled: { [weak self] in
                self?.stateSubject.value = .failedToProvision
            },
            onFailed: { error in
                VisaLogger.error("Failed to poll VA order status", error: error)
            }
        )
    }

    private func bind() {
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

// MARK: - Constants

private extension VirtualAccountManager {
    enum Constants {
        static let provisioningOrderPollInterval: TimeInterval = 60
    }
}
