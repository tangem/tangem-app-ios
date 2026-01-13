//
//  TangemPayAvailabilityService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemPay

public protocol TangemPayAvailabilityService {
    func loadEligibility() async throws -> TangemPayAvailabilityResponse
    func validateDeeplink(deeplinkString: String) async throws -> ValidateDeeplinkResponse
    func isPaeraCustomer(customerWalletId: String) async throws -> TangemPayIsPaeraCustomerResponse
}

class CommonTangemPayAvailabilityService {
    private let apiService: TangemPayAPIService<TangemPayAvailabilityAPITarget>
    private let apiType: VisaAPIType
    private let bffStaticToken: String

    init(
        apiType: VisaAPIType,
        apiService: TangemPayAPIService<TangemPayAvailabilityAPITarget>,
        bffStaticToken: String
    ) {
        self.apiType = apiType
        self.apiService = apiService
        self.bffStaticToken = bffStaticToken
    }
}

extension CommonTangemPayAvailabilityService: TangemPayAvailabilityService {
    func loadEligibility() async throws -> TangemPayAvailabilityResponse {
        try await apiService.request(
            .init(target: .getEligibility, apiType: apiType),
            format: .wrapped
        )
    }

    func validateDeeplink(deeplinkString: String) async throws -> ValidateDeeplinkResponse {
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
                target: .isPaeraCustomer(
                    customerWalletId: customerWalletId,
                    bffStaticToken: bffStaticToken
                ),
                apiType: apiType
            ),
            format: .wrapped
        )
    }
}
