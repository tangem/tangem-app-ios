//
//  CommonPaymentAccountServices.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public final class CommonPaymentAccountServices: PaymentAccountServicesProviding {
    public let availabilityService: PaymentAccountAvailabilityService
    public let authorizationService: PaymentAccountAuthorizationService
    public let customerService: CustomerInfoManagementService
    public let enrollmentStateFetcher: PaymentAccountEnrollmentStateFetcher
    public let orderStatusPollingService: PaymentAccountOrderStatusPollingService

    public init(
        customerWalletId: String,
        availabilityServiceBuilder: PaymentAccountAvailabilityServiceBuilder,
        authorizationServiceBuilder: PaymentAccountAuthorizationServiceBuilder,
        customerServiceBuilder: PaymentAccountCustomerInfoManagementServiceBuilder
    ) {
        availabilityService = availabilityServiceBuilder.build()
        authorizationService = authorizationServiceBuilder.build(customerWalletId: customerWalletId)
        customerService = customerServiceBuilder.build(authorizationTokensHandler: authorizationService)
        enrollmentStateFetcher = PaymentAccountEnrollmentStateFetcher(
            customerWalletId: customerWalletId,
            availabilityService: availabilityService,
            customerService: customerService
        )
        orderStatusPollingService = PaymentAccountOrderStatusPollingService(
            customerService: customerService
        )
    }
}
