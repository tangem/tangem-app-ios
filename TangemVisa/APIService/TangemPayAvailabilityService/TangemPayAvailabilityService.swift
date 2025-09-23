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
}

class CommonTangemPayAvailabilityService {
    private let apiService: APIService<TangemPayAvailabilityAPITarget>
    private let apiType: VisaAPIType

    init(apiType: VisaAPIType, apiService: APIService<TangemPayAvailabilityAPITarget>) {
        self.apiType = apiType
        self.apiService = apiService
    }
}

extension CommonTangemPayAvailabilityService: TangemPayAvailabilityService {
    func loadEligibility() async throws -> TangemPayAvailabilityResponse {
        try await apiService.request(
            .init(target: .getEligibility, apiType: apiType)
        )
    }

    func validateDeeplink(deeplinkString: String) async throws -> ValidateDeeplinkResponse {
        try await apiService.request(
            .init(
                target: .validateDeeplink(deeplinkString: deeplinkString),
                apiType: apiType
            )
        )
    }
}
