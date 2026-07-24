//
//  CommonPolymarketAPIService.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemFoundation
import TangemNetworkUtils

final class CommonPolymarketAPIService {
    private let provider: TangemProvider<PolymarketTarget>
    private let baseURL: URL

    private let decoder = JSONDecoder()

    init(provider: TangemProvider<PolymarketTarget>, baseURL: URL) {
        self.provider = provider
        self.baseURL = baseURL
    }
}

// MARK: - PolymarketAPIService

extension CommonPolymarketAPIService: PolymarketAPIService {
    func categories(locale: String?) async throws -> PolymarketDTO.CategoriesResponse {
        try await request(.categories(locale: locale))
    }

    func events(request: PolymarketEventsRequest) async throws -> PolymarketDTO.EventsPageResponse {
        try await self.request(.events(request))
    }

    func event(id: String) async throws -> PolymarketDTO.EventResponse {
        try await request(.event(id: id))
    }

    func search(request: PolymarketSearchRequest) async throws -> PolymarketDTO.EventsSearchResponse {
        try await self.request(.search(request))
    }

    func series() async throws -> PolymarketDTO.SeriesResponse {
        try await request(.series)
    }

    func seriesEvents(seriesId: String) async throws -> PolymarketDTO.SeriesEventsResponse {
        try await request(.seriesEvents(seriesId: seriesId))
    }
}

// MARK: - Private

private extension CommonPolymarketAPIService {
    func request<T: Decodable>(_ target: PolymarketTarget.Target) async throws -> T {
        let request = PolymarketTarget(baseURL: baseURL, target: target)

        do {
            let response = try await provider.requestPublisher(request).async()
            let filtered = try response.filterSuccessfulStatusAndRedirectCodes()
            return try decoder.decode(T.self, from: filtered.data)
        } catch let error as CancellationError {
            throw error
        } catch let error as MoyaError {
            throw Self.mapMoyaError(error, decoder: decoder)
        } catch {
            throw PolymarketAPIError.connection(underlying: error)
        }
    }
}

// MARK: - Error mapping

extension CommonPolymarketAPIService {
    static func mapMoyaError(_ error: MoyaError, decoder: JSONDecoder) -> PolymarketAPIError {
        guard let response = error.response else {
            // Forward the underlying transport error so cancellation / network codes stay inspectable.
            return .connection(underlying: error.underlyingError ?? error)
        }

        let problemDetail = try? decoder.decode(PolymarketProblemDetail.self, from: response.data)
        return .http(statusCode: response.statusCode, problemDetail: problemDetail)
    }
}
