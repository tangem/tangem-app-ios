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
    public let tiersEnabled: Bool

    public init(
        customerWalletId: String,
        availabilityService: TangemPayAvailabilityService,
        customerService: CustomerInfoManagementService,
        tiersEnabled: Bool
    ) {
        self.customerWalletId = customerWalletId
        self.availabilityService = availabilityService
        self.customerService = customerService
        self.tiersEnabled = tiersEnabled
    }

    public func getEnrollmentState() async throws(TangemPayAPIServiceError) -> (state: TangemPayEnrollmentState, customerId: String) {
        let customerInfo = try await customerService.loadCustomerInfo()
        let customerId = customerInfo.id

        if let productInstance = customerInfo.productInstance,
           customerInfo.state == .former {
            return (
                .cardDeactivated(
                    customerInfo: customerInfo,
                    productInstance: productInstance
                ), customerId
            )
        }

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

            case .deactivated:
                return (.cardDeactivated(
                    customerInfo: customerInfo,
                    productInstance: productInstance
                ), customerId)

            default:
                break
            }
        }

        if tiersEnabled {
            let activeTransitionOrders = try await customerService.findOrders(
                types: TangemPayOrderType.tariffPlanTransitionFamily,
                statuses: [.new, .processing]
            )

            return (activeTransitionOrders.isEmpty ? .planSelectNeeded : .issuingCard, customerId)
        } else {
            // Legacy flow: the card is auto-issued right after KYC.
            return (.issuingCard, customerId)
        }
    }
}
