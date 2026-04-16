//
//  CommonRestrictedCountriesGeoDefiner.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

class CommonRestrictedCountriesGeoDefiner: RestrictedCountriesGeoDefiner {
    private let geoDefiner: GeoDefiner = .init()

    func initialize() {
        geoDefiner.initialize()
    }

    func waitForGeoIpRegionIfNeeded() async {
        guard !isPhoneRegionCodeUK, !isPhoneRegionApplePayRestricted else {
            return
        }

        // add timeout to avoid app launch delay
        try? await Task.run(withTimeout: .seconds(3.0)) { [geoDefiner] in
            _ = try? await geoDefiner.fetchGeoIpRegionCode()
        }
    }

    // MARK: - UK

    var isUK: Bool {
        guard !isPhoneRegionCodeUK else {
            return true
        }

        return geoDefiner.geoIpRegionCode?.contains(Constants.ukRegionCode) ?? false
    }

    private var isPhoneRegionCodeUK: Bool {
        geoDefiner.phoneRegionCode?.contains(Constants.ukRegionCode) ?? false
    }

    // MARK: - Apple Pay

    var isApplePayAllowed: Bool {
        guard !isPhoneRegionApplePayRestricted else {
            return false
        }

        guard let code = geoDefiner.geoIpRegionCode else {
            return true
        }

        return !Constants.applePayRestrictedRegionCodes.contains(where: { code.contains($0) })
    }

    private var isPhoneRegionApplePayRestricted: Bool {
        guard let code = geoDefiner.phoneRegionCode else {
            return false
        }

        return Constants.applePayRestrictedRegionCodes.contains(where: { code.contains($0) })
    }
}

extension CommonRestrictedCountriesGeoDefiner {
    private enum Constants {
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
