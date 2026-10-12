//
//  TangemPayGeoRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemPay

protocol TangemPayGeoRepository {
    func countries() async throws -> [TangemPayGeoCountry]
    func regions(countryCode: String) async throws -> [TangemPayGeoRegion]
}

final class CommonTangemPayGeoRepository {
    private let geoService: any TangemPayGeoService

    init(geoService: any TangemPayGeoService = TangemPayGeoServiceBuilder().build()) {
        self.geoService = geoService
    }
}

// MARK: - TangemPayGeoRepository

extension CommonTangemPayGeoRepository: TangemPayGeoRepository {
    func countries() async throws -> [TangemPayGeoCountry] {
        try await geoService.getCountries()
    }

    func regions(countryCode: String) async throws -> [TangemPayGeoRegion] {
        try await geoService.getRegions(countryCode: countryCode)
    }
}
