//
//  CommonGeoEligibilityService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

class CommonGeoEligibilityService: GeoEligibilityService {
    private let geoDefiner: GeoDefiner

    init(geoDefiner: GeoDefiner = .init()) {
        self.geoDefiner = geoDefiner
    }

    func initialize() {
        geoDefiner.initialize()
    }

    func waitForGeoIpRegionIfNeeded() async {
        // add timeout to avoid app launch delay
        try? await Task.run(withTimeout: Constants.geoIpRegionCodeTimeout) { [geoDefiner] in
            await geoDefiner.waitForUpdateIfNeeded()
        }
    }

    func fetchGeoIpRegionCode() async -> String? {
        await waitForGeoIpRegionIfNeeded()

        return regionCode
    }

    var regionCode: String? {
        geoDefiner.geoIpRegionCode ?? geoDefiner.phoneRegionCode
    }

    // MARK: - UK

    var isUK: Bool {
        regionCode?.caseInsensitiveCompare(Constants.ukRegionCode) == .orderedSame
    }

    // MARK: - Apple Pay

    var isApplePayAllowed: Bool {
        guard let code = regionCode else {
            return true
        }

        return !Constants.applePayRestrictedRegionCodes.contains(code.lowercased())
    }
}

extension CommonGeoEligibilityService {
    private enum Constants {
        static let geoIpRegionCodeTimeout: Duration = .seconds(3.0)

        static let ukRegionCode: String = "gb"

        static let applePayRestrictedRegionCodes: Set<String> = [
            "us", // United States
            "gb", // United Kingdom
            "af", // Afghanistan
            "ao", // Angola
            "aq", // Antarctica
            "ax", // Åland Islands
            "bb", // Barbados
            "bd", // Bangladesh
            "bi", // Burundi
            "bo", // Bolivia
            "cd", // Democratic Republic of the Congo
            "cf", // Central African Republic
            "cg", // Congo
            "cl", // Chile
            "cn", // China
            "co", // Colombia
            "cr", // Costa Rica
            "cu", // Cuba
            "dz", // Algeria
            "ec", // Ecuador
            "eh", // Western Sahara
            "gf", // French Guiana
            "gt", // Guatemala
            "gu", // Guam
            "gw", // Guinea-Bissau
            "hn", // Honduras
            "ht", // Haiti
            "hu", // Hungary
            "iq", // Iraq
            "ir", // Iran
            "is", // Iceland
            "kg", // Kyrgyzstan
            "kh", // Cambodia
            "kp", // North Korea
            "lb", // Lebanon
            "lr", // Liberia
            "ly", // Libya
            "ma", // Morocco
            "ml", // Mali
            "mm", // Myanmar
            "ni", // Nicaragua
            "np", // Nepal
            "pa", // Panama
            "pf", // French Polynesia
            "pg", // Papua New Guinea
            "pk", // Pakistan
            "ps", // Palestine
            "ru", // Russian Federation
            "sa", // Saudi Arabia
            "sd", // Sudan
            "sl", // Sierra Leone
            "so", // Somalia
            "ss", // South Sudan
            "sy", // Syria
            "tn", // Tunisia
            "ve", // Venezuela
            "xk", // Kosovo
            "ye", // Yemen
            "zw", // Zimbabwe
        ]
    }
}
