//
//  TangemPayGeoService.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public protocol TangemPayGeoService {
    func getCountries() async throws -> [TangemPayGeoCountry]
    func getRegions(countryCode: String) async throws -> [TangemPayGeoRegion]
}
