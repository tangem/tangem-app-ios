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
