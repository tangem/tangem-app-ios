//
//  CommonTangemPayAvailabilityService.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

final class CommonTangemPayAvailabilityService {
    private let apiService: TangemPayAPIService<TangemPayAvailabilityAPITarget>
    private let apiType: VisaAPIType

    init(
        apiType: VisaAPIType,
        apiService: TangemPayAPIService<TangemPayAvailabilityAPITarget>,
    ) {
        self.apiType = apiType
        self.apiService = apiService
    }

    private func request<T: Decodable>(for target: TangemPayAvailabilityAPITarget.Target) async throws(TangemPayAPIServiceError) -> T {
        try await apiService.request(
            .init(
                target: target,
                apiType: apiType
            )
        )
    }
}

extension CommonTangemPayAvailabilityService: TangemPayAvailabilityService {
    func loadEligibility() async throws -> TangemPayAvailabilityResponse {
        try await request(for: .getEligibility)
    }

    func validateDeeplink(deeplinkString: String) async throws -> ValidateDeeplinkResponse {
        try await request(for: .validateDeeplink(deeplinkString: deeplinkString))
    }

    func isPaeraCustomer(customerWalletId: String) async throws -> TangemPayIsPaeraCustomerResponse {
        try await request(for: .isPaeraCustomer(customerWalletId: customerWalletId))
    }
}
