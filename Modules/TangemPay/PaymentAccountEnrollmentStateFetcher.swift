//
//  PaymentAccountEnrollmentStateFetcher.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public struct PaymentAccountEnrollmentStateFetcher {
    public let customerWalletId: String
    public let availabilityService: PaymentAccountAvailabilityService
    public let customerService: CustomerInfoManagementService

    public init(
        customerWalletId: String,
        availabilityService: PaymentAccountAvailabilityService,
        customerService: CustomerInfoManagementService
    ) {
        self.customerWalletId = customerWalletId
        self.availabilityService = availabilityService
        self.customerService = customerService
    }

    public func getEnrollmentState() async throws(TangemPayAPIServiceError) -> (state: PaymentAccountEnrollmentState, customerId: String) {
        let customerInfo = try await customerService.loadCustomerInfo()
        let customerId = customerInfo.id

        guard customerInfo.kyc?.status == .approved else {
            if case .declined = customerInfo.kyc?.status {
                return (.kycDeclined, customerId)
            }
            return (.kycRequired(productInstanceExists: customerInfo.productInstance != nil), customerId)
        }

        if let productInstance = customerInfo.productInstance {
            switch productInstance.status {
            case .active, .blocked:
                return (.enrolled(customerInfo: customerInfo, productInstance: productInstance), customerId)

            default:
                break
            }
        }

        return (.issuingCard, customerId)
    }
}
