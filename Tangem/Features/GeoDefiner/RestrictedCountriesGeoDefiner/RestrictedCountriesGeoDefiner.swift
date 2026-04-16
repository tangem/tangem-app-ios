//
//  RestrictedCountriesGeoDefiner.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

protocol RestrictedCountriesGeoDefiner: Initializable {
    func waitForGeoIpRegionIfNeeded() async
    var isUK: Bool { get }
    var isApplePayAllowed: Bool { get }
}

private struct RestrictedCountriesGeoDefinerKey: InjectionKey {
    static var currentValue: RestrictedCountriesGeoDefiner = CommonRestrictedCountriesGeoDefiner()
}

extension InjectedValues {
    var restrictedCountriesGeoDefiner: RestrictedCountriesGeoDefiner {
        get { Self[RestrictedCountriesGeoDefinerKey.self] }
        set { Self[RestrictedCountriesGeoDefinerKey.self] = newValue }
    }
}
