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

    /// Awaits the GeoIP country for a bounded time, falling back to the device region if it neither arrived in time
    /// nor could be resolved.
    func fetchGeoIpRegionCode() async -> String?

    /// Whatever is known right now: the GeoIP country once it has arrived, the device region until then.
    var regionCode: String? { get }
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
