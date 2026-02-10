//
//  TangemPayEnrollmentStateFetcher.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public struct TangemPayEnrollmentStateFetcher {
    public let customerWalletId: String
    public let availabilityService: TangemPayAvailabilityService
    public let customerService: CustomerInfoManagementService

    public init(
        customerWalletId: String,
        availabilityService: TangemPayAvailabilityService,
        customerService: CustomerInfoManagementService
    ) {
        self.customerWalletId = customerWalletId
        self.availabilityService = availabilityService
        self.customerService = customerService
    }

    public func getEnrollmentState() async throws(TangemPayAPIServiceError) -> (state: TangemPayEnrollmentState, customerId: String) {
        let customerInfo = try await customerService.loadCustomerInfo()
        let customerId = customerInfo.id

        if let productInstance = customerInfo.productInstance {
            switch productInstance.status {
            case .active, .blocked:
                return (.enrolled(customerInfo: customerInfo, productInstance: productInstance), customerId)

            default:
                break
            }
        }

        guard customerInfo.kyc?.status == .approved else {
            if case .declined = customerInfo.kyc?.status {
                return (.kycDeclined, customerId)
            }
            return (.kycRequired, customerId)
        }

        return (.issuingCard, customerId)
    }
}
