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
    public let isUnifiedOnboardingEnabled: Bool

    public init(
        customerWalletId: String,
        availabilityService: TangemPayAvailabilityService,
        customerService: CustomerInfoManagementService,
        isCustomerSummaryEnabled: Bool,
        isUnifiedOnboardingEnabled: Bool
    ) {
        self.customerWalletId = customerWalletId
        self.availabilityService = availabilityService
        self.customerService = customerService
        self.isCustomerSummaryEnabled = isCustomerSummaryEnabled
        self.isUnifiedOnboardingEnabled = isUnifiedOnboardingEnabled
    }

    public func getEnrollmentState() async throws(TangemPayAPIServiceError) -> EnrollmentResult {
        let customerInfo = try await customerService.loadCustomerInfo()
        let customerId = customerInfo.id

        if isCustomerSummaryEnabled {
            let summary = try await customerService.loadCustomerSummary()
            let state = TangemPaySummaryEnrollmentResolver.resolve(
                summary: summary,
                isUnifiedOnboardingEnabled: isUnifiedOnboardingEnabled
            )
            return EnrollmentResult(state: state, customerId: customerId, customerInfo: customerInfo, summary: summary)
        }

        let state = try await getLegacyEnrollmentState(customerInfo: customerInfo)
        return EnrollmentResult(state: state, customerId: customerId, customerInfo: customerInfo, summary: nil)
    }

    private func getLegacyEnrollmentState(
        customerInfo: VisaCustomerInfoResponse
    ) async throws(TangemPayAPIServiceError) -> TangemPayEnrollmentState {
        if customerInfo.state == .former {
            return .cardDeactivated
        }

        switch customerInfo.kyc?.status {
        case .approved:
            break
        case .declined:
            return .kycDeclined
        case .inProgress:
            return .kycInProgress
        case .required, .undefined, nil:
            return .kycRequired
        }

        let cardInstances = customerInfo.cardProductInstances

        if cardInstances.contains(where: { $0.status == .active || $0.status == .blocked }) {
            return .enrolled
        }

        if !cardInstances.isEmpty,
           cardInstances.allSatisfy({ $0.status == .deactivated || $0.status == .canceled }) {
            return .cardDeactivated
        }

        if customerInfo.paymentAccount != nil {
            return .enrolled
        }

        // A campaign card is ordered before KYC, so that order — not a plan transition — is what stands in
        // for the plan the user was never asked to pick.
        let orderTypes = TangemPayOrderType.tariffPlanTransitionFamily + TangemPayOrderType.cardIssueFamily

        let activeOrders = try await customerService.findOrders(
            types: orderTypes,
            statuses: [.new, .processing]
        )

        if !activeOrders.isEmpty {
            return .enrolled
        }

        return .planSelectNeeded
    }
}

public extension TangemPayEnrollmentStateFetcher {
    struct EnrollmentResult {
        public let state: TangemPayEnrollmentState
        public let customerId: String
        public let customerInfo: VisaCustomerInfoResponse
        public let summary: TangemPayCustomerSummaryResponse?
    }
}
