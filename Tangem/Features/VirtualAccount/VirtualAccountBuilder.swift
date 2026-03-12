//
//  VirtualAccountBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation
import TangemPay

final class VirtualAccountBuilder {
    private let userWalletId: UserWalletId
    private let keysRepository: KeysRepository
    private let signer: any TangemSigner

    private var customerWalletId: String {
        userWalletId.stringValue
    }

    private lazy var services: PaymentAccountServicesProviding = CommonPaymentAccountServices(
        customerWalletId: customerWalletId,
        availabilityServiceBuilder: PaymentAccountAvailabilityServiceBuilder(),
        authorizationServiceBuilder: PaymentAccountAuthorizationServiceBuilder(),
        customerServiceBuilder: PaymentAccountCustomerInfoManagementServiceBuilder()
    )

    init(
        userWalletId: UserWalletId,
        keysRepository: KeysRepository,
        signer: any TangemSigner
    ) {
        self.userWalletId = userWalletId
        self.keysRepository = keysRepository
        self.signer = signer
    }

    func buildVirtualAccountManager() -> VirtualAccountManager {
        VirtualAccountManager(
            userWalletId: userWalletId,
            keysRepository: keysRepository,
            availabilityService: services.availabilityService,
            authorizationService: services.authorizationService,
            customerService: services.customerService,
            enrollmentStateFetcher: services.enrollmentStateFetcher,
            orderStatusPollingService: services.orderStatusPollingService,
            orderIdStorage: AppSettings.shared,
            paeraCustomerFlagRepository: AppSettings.shared,
            cachedStateStorage: AppSettings.shared,
            paymentWalletFlagStorage: AppSettings.shared
        )
    }
}
