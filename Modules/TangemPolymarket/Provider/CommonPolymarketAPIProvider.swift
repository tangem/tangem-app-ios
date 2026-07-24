//
//  CommonPolymarketAPIProvider.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils

public final class CommonPolymarketAPIProvider {
    private let service: PolymarketAPIService
    private let mapper: PolymarketMapper

    public init(
        baseURL: URL,
        networkConfiguration: TangemProviderConfiguration,
        headers: [APIHeaderKeyInfo]
    ) {
        let provider = TangemProvider<PolymarketTarget>(
            configuration: networkConfiguration,
            additionalPlugins: [NetworkHeadersPlugin(networkHeaders: headers)]
        )
        service = CommonPolymarketAPIService(provider: provider, baseURL: baseURL)
        mapper = PolymarketMapper()
    }
}

// MARK: - PolymarketAPIProvider

extension CommonPolymarketAPIProvider: PolymarketAPIProvider {
    public func categories(locale: String?) async throws -> [PolymarketCategory] {
        let response = try await service.categories(locale: locale)
        return response.categories.map(mapper.mapCategory)
    }

    public func events(request: PolymarketEventsRequest) async throws -> PolymarketEventsPage {
        let response = try await service.events(request: request)
        return mapper.mapEventsPage(response)
    }

    public func event(id: String) async throws -> PolymarketEvent {
        let response = try await service.event(id: id)
        return mapper.mapEvent(response.event)
    }

    public func search(request: PolymarketSearchRequest) async throws -> PolymarketSearchResult {
        let response = try await service.search(request: request)
        return mapper.mapSearchResult(response)
    }

    public func series() async throws -> [PolymarketSeries] {
        let response = try await service.series()
        return response.series.map(mapper.mapSeries)
    }

    public func seriesEvents(seriesId: String) async throws -> PolymarketSeriesEvents {
        let response = try await service.seriesEvents(seriesId: seriesId)
        return mapper.mapSeriesEvents(response)
    }
}
