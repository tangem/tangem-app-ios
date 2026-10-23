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

        if customerInfo.state == .former {
            return (.cardDeactivated(customerInfo: customerInfo), customerId)
        }

        switch customerInfo.kyc?.status {
        case .approved:
            break
        case .declined:
            return (.kycDeclined, customerId)
        case .inProgress:
            return (.kycInProgress, customerId)
        case .required, .expired, .undefined, nil:
            return (.kycRequired, customerId)
        }

        let cardInstances = customerInfo.cardProductInstances

        if cardInstances.contains(where: { $0.status == .active || $0.status == .blocked }) {
            return (.enrolled(customerInfo: customerInfo), customerId)
        }

        if !cardInstances.isEmpty,
           cardInstances.allSatisfy({ $0.status == .deactivated || $0.status == .canceled }) {
            return (.cardDeactivated(customerInfo: customerInfo), customerId)
        }

        if customerInfo.paymentAccount != nil {
            return (.enrolled(customerInfo: customerInfo), customerId)
        }

        // A campaign card is ordered before KYC, so that order — not a plan transition — is what stands in
        // for the plan the user was never asked to pick.
        let orderTypes = TangemPayOrderType.tariffPlanTransitionFamily + TangemPayOrderType.cardIssueFamily

        let activeOrders = try await customerService.findOrders(
            types: orderTypes,
            statuses: [.new, .processing]
        )

        if !activeOrders.isEmpty {
            return (.enrolled(customerInfo: customerInfo), customerId)
        }

        return (.planSelectNeeded, customerId)
    }
}
