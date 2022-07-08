//
//  GeoIpService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine

protocol GeoIpService {
    func regionCode() -> AnyPublisher<String, Never>
}

private struct GeoIpServiceKey: InjectionKey {
    static var currentValue: GeoIpService = CommonGeoIpService()
}

extension InjectedValues {
    var geoIpService: GeoIpService {
        get { Self[GeoIpServiceKey.self] }
        set { Self[GeoIpServiceKey.self] = newValue }
    }
}
