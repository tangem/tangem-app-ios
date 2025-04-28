//
//  CommonUKGeoDefiner.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

class CommonUKGeoDefiner: UKGeoDefiner {
    private let geoDefiner: GeoDefiner = .init()

    func initialize() {
        geoDefiner.initialize()
    }

    var isUK: Bool {
        let ipInUK = geoDefiner.geoIpRegionCode?.contains(Constants.ukRegionCode) ?? false
        let phoneCodeInUK = geoDefiner.phoneRegionCode?.contains(Constants.ukRegionCode) ?? false

        return ipInUK || phoneCodeInUK
    }
}

extension CommonUKGeoDefiner {
    private enum Constants {
        static let ukRegionCode: String = "gb"
    }
}
