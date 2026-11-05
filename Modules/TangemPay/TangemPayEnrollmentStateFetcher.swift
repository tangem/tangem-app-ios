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
    public let isCustomerSummaryEnabled: Bool

    public init(
        customerWalletId: String,
        availabilityService: TangemPayAvailabilityService,
        customerService: CustomerInfoManagementService,
        isCustomerSummaryEnabled: Bool
    ) {
        self.customerWalletId = customerWalletId
        self.availabilityService = availabilityService
        self.customerService = customerService
        self.isCustomerSummaryEnabled = isCustomerSummaryEnabled
    }

    public func getEnrollmentState() async throws(TangemPayAPIServiceError) -> (state: TangemPayEnrollmentState, customerId: String) {
        let customerInfo = try await customerService.loadCustomerInfo()
        let summary = isCustomerSummaryEnabled ? try await customerService.loadCustomerSummary() : nil
        let customerId = customerInfo.id

        let customerState: VisaCustomerInfoResponse.CustomerState = if isCustomerSummaryEnabled, let summary {
            VisaCustomerInfoResponse.CustomerState(summary.customerStatus)
        } else {
            customerInfo.state
        }

        if customerState == .former {
            return (.cardDeactivated(customerInfo: customerInfo, summary: summary), customerId)
        }

        let kycStatus: VisaCustomerInfoResponse.KYCStatus? = if isCustomerSummaryEnabled, let summary {
            VisaCustomerInfoResponse.KYCStatus(summary.kycStatus)
        } else {
            customerInfo.kyc?.status
        }

        switch kycStatus {
        case .approved:
            break
        case .declined:
            return (.kycDeclined, customerId)
        case .inProgress:
            return (.kycInProgress, customerId)
        case .required, .undefined, nil:
            return (.kycRequired, customerId)
        }

        if isCustomerSummaryEnabled, let summary {
            if summary.paymentAccount.areAllCardsDeactivated {
                return (.cardDeactivated(customerInfo: customerInfo, summary: summary), customerId)
            }

            switch summary.paymentAccount.activation.status {
            case .processing, .completed:
                return (.enrolled(customerInfo: customerInfo, summary: summary), customerId)
            case .failed:
                return (.failedToIssueCard(customerInfo: customerInfo, summary: summary), customerId)
            case .notStarted:
                return (.planSelectNeeded, customerId)
            case .unavailable, .deactivated, .undefined:
                return (.unavailable, customerId)
            }
        } else {
            let cardInstances = customerInfo.cardProductInstances

            if cardInstances.contains(where: { $0.status == .active || $0.status == .blocked }) {
                return (.enrolled(customerInfo: customerInfo, summary: summary), customerId)
            }

            if !cardInstances.isEmpty,
               cardInstances.allSatisfy({ $0.status == .deactivated || $0.status == .canceled }) {
                return (.cardDeactivated(customerInfo: customerInfo, summary: summary), customerId)
            }

            if customerInfo.paymentAccount != nil {
                return (.enrolled(customerInfo: customerInfo, summary: summary), customerId)
            }

            // A campaign card is ordered before KYC, so that order — not a plan transition — is what stands in
            // for the plan the user was never asked to pick.
            let orderTypes = TangemPayOrderType.tariffPlanTransitionFamily + TangemPayOrderType.cardIssueFamily

            let activeOrders = try await customerService.findOrders(
                types: orderTypes,
                statuses: [.new, .processing]
            )

            if !activeOrders.isEmpty {
                return (.enrolled(customerInfo: customerInfo, summary: summary), customerId)
            }

            return (.planSelectNeeded, customerId)
        }
    }
}
