//
//  PaymentAccountServicesProviding.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public protocol PaymentAccountServicesProviding {
    var availabilityService: PaymentAccountAvailabilityService { get }
    var authorizationService: PaymentAccountAuthorizationService { get }
    var customerService: CustomerInfoManagementService { get }
    var enrollmentStateFetcher: PaymentAccountEnrollmentStateFetcher { get }
    var orderStatusPollingService: PaymentAccountOrderStatusPollingService { get }
}
