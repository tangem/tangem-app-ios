//
//  CommonUKGeoDefiner.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

class CommonUKGeoDefiner: UKGeoDefiner {
    private let geoDefiner: GeoDefiner = .init()

    func initialize() {
        geoDefiner.initialize()
    }

    func waitForGeoIpRegionIfNeeded() async {
        guard !isPhoneRegionCodeUK else {
            return
        }

        // add timeout to avoid app launch delay
        try? await runTask(withTimeout: 3) { [geoDefiner] in
            _ = try? await geoDefiner.fetchGeoIpRegionCode()
        }
    }

    var isUK: Bool {
        true
//        guard !isPhoneRegionCodeUK else {
//            return true
//        }
//
//        return geoDefiner.geoIpRegionCode?.contains(Constants.ukRegionCode) ?? false
    }

    private var isPhoneRegionCodeUK: Bool {
        geoDefiner.phoneRegionCode?.contains(Constants.ukRegionCode) ?? false
    }
}

extension CommonUKGeoDefiner {
    private enum Constants {
        static let ukRegionCode: String = "gb"
    }
}
