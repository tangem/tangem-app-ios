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

        if customerInfo.state == .former, !customerInfo.productInstances.isEmpty {
            return (.cardDeactivated(customerInfo: customerInfo), customerId)
        }

        guard customerInfo.kyc?.status == .approved else {
            if case .declined = customerInfo.kyc?.status {
                return (.kycDeclined, customerId)
            }
            return (
                .kycRequired(productInstanceExists: !customerInfo.productInstances.isEmpty),
                customerId
            )
        }

        if !customerInfo.productInstances.isEmpty {
            let hasActiveOrBlocked = customerInfo.productInstances.contains {
                $0.status == .active || $0.status == .blocked
            }
            if hasActiveOrBlocked {
                return (.enrolled(customerInfo: customerInfo), customerId)
            }

            let allTerminal = customerInfo.productInstances.allSatisfy {
                $0.status == .deactivated || $0.status == .canceled
            }
            if allTerminal {
                return (.cardDeactivated(customerInfo: customerInfo), customerId)
            }
        }

        return (.issuingCard, customerId)
    }
}
