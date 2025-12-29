//
//  TangemPayEnrollmentStateFetcher.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemVisa

struct TangemPayEnrollmentStateFetcher {
    let customerWalletId: String
    let customerInfoManagementService: CustomerInfoManagementService

    func getEnrollmentState() async throws(TangemPayAPIServiceError) -> TangemPayEnrollmentState {
        guard await isPaeraCustomer() else {
            return .notEnrolled
        }

        let customerInfo = try await customerInfoManagementService.loadCustomerInfo()

        if let productInstance = customerInfo.productInstance {
            switch productInstance.status {
            case .active, .blocked:
                return .enrolled(customerInfo)

            default:
                break
            }
        }

        guard customerInfo.kyc?.status == .approved else {
            return .kyc
        }

        return .issuingCard
    }

    private func isPaeraCustomer() async -> Bool {
        if await AppSettings.shared.tangemPayIsPaeraCustomer[customerWalletId, default: false] {
            return true
        }

        let availabilityService = TangemPayAPIServiceBuilder().buildTangemPayAvailabilityService()
        guard let isPaeraCustomerResponse = try? await availabilityService.isPaeraCustomer(customerWalletId: customerWalletId) else {
            return false
        }

        await MainActor.run {
            AppSettings.shared.tangemPayIsPaeraCustomer[customerWalletId] = true
            AppSettings.shared.tangemPayIsKYCHiddenForCustomerWalletId[customerWalletId] = !isPaeraCustomerResponse.isTangemPayEnabled
        }

        return true
    }
}
