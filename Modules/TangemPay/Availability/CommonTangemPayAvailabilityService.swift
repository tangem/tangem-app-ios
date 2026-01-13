//
//  CommonTangemPayAvailabilityService.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct CommonTangemPayAvailabilityService {
    let apiService: TangemPayAPIService<TangemPayAvailabilityAPITarget>
    let apiType: TangemPayAPIType
}

extension CommonTangemPayAvailabilityService: TangemPayAvailabilityService {
    func eligibility() async throws -> TangemPayEligibilityResponse {
        try await apiService.request(
            .init(
                target: .getEligibility,
                apiType: apiType
            ),
            format: .wrapped
        )
    }

    func validateDeeplink(deeplinkString: String) async throws -> TangemPayValidateDeeplinkResponse {
        try await apiService.request(
            .init(
                target: .validateDeeplink(deeplinkString: deeplinkString),
                apiType: apiType
            ),
            format: .wrapped
        )
    }

    func isPaeraCustomer(customerWalletId: String) async throws -> TangemPayIsPaeraCustomerResponse {
        try await apiService.request(
            .init(
                target: .isPaeraCustomer(customerWalletId: customerWalletId),
                apiType: apiType
            ),
            format: .wrapped
        )
    }
}
