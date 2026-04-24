//
//  GeoEligibilityService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

protocol GeoEligibilityService: Initializable {
    func waitForGeoIpRegionIfNeeded() async
    var isUK: Bool { get }
    var isApplePayAllowed: Bool { get }
}

private struct GeoEligibilityServiceKey: InjectionKey {
    static var currentValue: GeoEligibilityService = CommonGeoEligibilityService()
}

extension InjectedValues {
    var geoEligibilityService: GeoEligibilityService {
        get { Self[GeoEligibilityServiceKey.self] }
        set { Self[GeoEligibilityServiceKey.self] = newValue }
    }
}
