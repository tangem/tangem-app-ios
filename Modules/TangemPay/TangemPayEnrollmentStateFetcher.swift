//
//  TangemPayEnrollmentStateFetcher.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public struct TangemPayEnrollmentStateFetcher {
    public let customerWalletId: String
    public let paeraCustomerFlagRepository: TangemPayPaeraCustomerFlagRepository
    public let availabilityService: TangemPayAvailabilityService
    public let customerService: CustomerInfoManagementService

    public init(
        customerWalletId: String,
        paeraCustomerFlagRepository: TangemPayPaeraCustomerFlagRepository,
        availabilityService: TangemPayAvailabilityService,
        customerService: CustomerInfoManagementService
    ) {
        self.customerWalletId = customerWalletId
        self.paeraCustomerFlagRepository = paeraCustomerFlagRepository
        self.availabilityService = availabilityService
        self.customerService = customerService
    }

    public func getEnrollmentState(customerWalletAddress: String?) async throws(TangemPayAPIServiceError) -> TangemPayEnrollmentState {
        guard await isPaeraCustomer() else {
            return .notEnrolled
        }

        guard let customerWalletAddress else {
            throw .unauthorized
        }

        let customerInfo = try await customerService.loadCustomerInfo()

        if let productInstance = customerInfo.productInstance {
            switch productInstance.status {
            case .active, .blocked:
                return .enrolled(customerInfo: customerInfo, productInstance: productInstance)

            default:
                break
            }
        }

        guard customerInfo.kyc?.status == .approved else {
            if case .declined = customerInfo.kyc?.status {
                return .kycDeclined
            }
            return .kycRequired
        }

        return .issuingCard(customerWalletAddress: customerWalletAddress)
    }

    private func isPaeraCustomer() async -> Bool {
        if paeraCustomerFlagRepository.isPaeraCustomer(customerWalletId: customerWalletId) {
            return true
        }

        guard let isPaeraCustomerResponse = try? await availabilityService.isPaeraCustomer(customerWalletId: customerWalletId) else {
            return false
        }

        paeraCustomerFlagRepository.setIsPaeraCustomer(true, for: customerWalletId)
        paeraCustomerFlagRepository.setIsKYCHidden(!isPaeraCustomerResponse.isTangemPayEnabled, for: customerWalletId)

        return true
    }
}
