//
//  TangemPayEnrollmentStateFetcher.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemPay
import TangemVisa

struct TangemPayEnrollmentStateFetcher {
    let customerWalletId: String
    let keysRepository: KeysRepository
    let customerService: TangemPayCustomerService

    func getEnrollmentState() async throws(TangemPayAPIServiceError) -> TangemPayEnrollmentState {
        guard let (customerWalletAddress, _) = TangemPayUtilities.getCustomerWalletAddressAndAuthorizationTokens(
            customerWalletId: customerWalletId,
            keysRepository: keysRepository
        ) else {
            throw .unauthorized
        }

        guard await isPaeraCustomer() else {
            return .notEnrolled
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
            return .kyc
        }

        return .issuingCard(customerWalletAddress: customerWalletAddress)
    }

    private func isPaeraCustomer() async -> Bool {
        if await AppSettings.shared.tangemPayIsPaeraCustomer[customerWalletId, default: false] {
            return true
        }

        let availabilityService = TangemPayAvailabilityServiceBuilder().build()
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
