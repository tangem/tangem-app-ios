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
    private let paeraCustomerFlagRepository: TangemPayPaeraCustomerFlagRepository

    init(
        apiType: VisaAPIType,
        apiService: TangemPayAPIService<TangemPayAvailabilityAPITarget>,
        paeraCustomerFlagRepository: TangemPayPaeraCustomerFlagRepository
    ) {
        self.apiType = apiType
        self.apiService = apiService
        self.paeraCustomerFlagRepository = paeraCustomerFlagRepository
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

    func getIsPaeraCustomer(customerWalletId: String) async throws -> TangemPayIsPaeraCustomerResponse {
        try await request(for: .isPaeraCustomer(customerWalletId: customerWalletId))
    }

    func isPaeraCustomer(customerWalletId: String) async -> Bool {
        if paeraCustomerFlagRepository.isKYCHidden(customerWalletId: customerWalletId) {
            return false
        }

        if paeraCustomerFlagRepository.isPaeraCustomer(customerWalletId: customerWalletId) {
            return true
        }

        let isPaeraCustomerResponse: TangemPayIsPaeraCustomerResponse
        do {
            isPaeraCustomerResponse = try await getIsPaeraCustomer(customerWalletId: customerWalletId)
        } catch {
            return false
        }

        paeraCustomerFlagRepository.setIsPaeraCustomer(true, for: customerWalletId)
        paeraCustomerFlagRepository.setIsKYCHidden(!isPaeraCustomerResponse.isTangemPayEnabled, for: customerWalletId)

        return true
    }
}
