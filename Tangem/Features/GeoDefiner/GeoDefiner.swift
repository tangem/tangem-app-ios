//
//  GeoDefiner.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

class GeoDefiner: Initializable {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    public var geoIpRegionCode: String?
    public var phoneRegionCode: String? {
        Locale.current.regionCode?.lowercased()
    }

    private var ipRegionCodeTask: Task<Void, Error>?

    func initialize() {
        ipRegionCodeTask = TangemFoundation.runTask(in: self) {
            $0.geoIpRegionCode = try await $0.tangemApiService.loadGeo().async()
        }
    }
}
