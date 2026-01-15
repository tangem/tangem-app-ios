//
//  TangemPayAvailabilityService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public protocol TangemPayAvailabilityService {
    func loadEligibility() async throws -> TangemPayAvailabilityResponse
    func validateDeeplink(deeplinkString: String) async throws -> ValidateDeeplinkResponse
    func isPaeraCustomer(customerWalletId: String) async throws -> TangemPayIsPaeraCustomerResponse
}

class CommonTangemPayAvailabilityService {
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
