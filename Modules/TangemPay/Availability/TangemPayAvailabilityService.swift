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
    func getCampaignImages(deeplinkValue: String) async throws -> TangemPayImagesResponse
    func getIsPaeraCustomer(customerWalletId: String) async throws -> TangemPayIsPaeraCustomerResponse
    func isPaeraCustomer(customerWalletId: String) async -> Bool
}
