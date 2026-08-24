//
//  CommonPolymarketGeoblockService.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemFoundation
import TangemNetworkUtils

final class CommonPolymarketGeoblockService {
    private let provider: TangemProvider<PolymarketGeoblockTarget>
    private let baseURL: URL

    private let decoder = JSONDecoder()

    init(provider: TangemProvider<PolymarketGeoblockTarget>, baseURL: URL) {
        self.provider = provider
        self.baseURL = baseURL
    }
}

// MARK: - PolymarketGeoblockService protocol conformance

extension CommonPolymarketGeoblockService: PolymarketGeoblockService {
    func geoblock() async throws -> PolymarketGeoblock {
        let target = PolymarketGeoblockTarget(baseURL: baseURL)

        do {
            let response = try await provider.requestPublisher(target).async()
            let filtered = try response.filterSuccessfulStatusAndRedirectCodes()
            let dto = try decoder.decode(PolymarketDTO.GeoblockResponse.self, from: filtered.data)

            return PolymarketGeoblock(isBlocked: dto.blocked, country: dto.country, region: dto.region)
        } catch let error as CancellationError {
            throw error
        } catch let error as MoyaError {
            throw CommonPolymarketAPIService.mapMoyaError(error, decoder: decoder)
        } catch {
            throw PolymarketAPIError.connection(underlying: error)
        }
    }
}
