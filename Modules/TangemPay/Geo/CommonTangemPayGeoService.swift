//
//  CommonTangemPayGeoService.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

final class CommonTangemPayGeoService {
    private let apiService: TangemPayAPIService<TangemPayGeoAPITarget>
    private let apiType: VisaAPIType

    init(
        apiType: VisaAPIType,
        apiService: TangemPayAPIService<TangemPayGeoAPITarget>
    ) {
        self.apiType = apiType
        self.apiService = apiService
    }

    private func request<T: Decodable>(for target: TangemPayGeoAPITarget.Target) async throws(TangemPayAPIServiceError) -> T {
        try await apiService.request(
            .init(
                target: target,
                apiType: apiType
            )
        )
    }
}

extension CommonTangemPayGeoService: TangemPayGeoService {
    func getCountries() async throws -> [TangemPayGeoCountry] {
        try await request(for: .countries)
    }

    func getRegions(countryCode: String) async throws -> [TangemPayGeoRegion] {
        try await request(for: .regions(countryCode: countryCode))
    }
}
