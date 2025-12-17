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
        Locale.current.region?.identifier.lowercased()
    }

    private var ipRegionCodeTask: Task<String, Error>?

    func initialize() {
        runTask(in: self) {
            $0.geoIpRegionCode = try await $0.fetchGeoIpRegionCode()
        }
    }

    func fetchGeoIpRegionCode() async throws -> String? {
        if let geoIpRegionCode {
            return geoIpRegionCode
        }

        if let ipRegionCodeTask {
            return try await ipRegionCodeTask.value
        }

        let task: Task<String, Error> = Task { [weak self] in
            guard let self else {
                throw CancellationError()
            }

            defer {
                ipRegionCodeTask = nil
            }

            return try await tangemApiService.loadGeo().async()
        }

        ipRegionCodeTask = task

        return try await task.value
    }
}
