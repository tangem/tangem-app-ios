//
//  PolymarketEventSportsService.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemFoundation
import TangemNetworkUtils

public protocol PolymarketEventSportsService {
    func sports(eventSlug: String) async throws -> PolymarketEventSports
}

final class CommonPolymarketEventSportsService {
    private let provider: TangemProvider<PolymarketEventSportsTarget>
    private let baseURL: URL

    private let decoder = JSONDecoder()
    private let mapper = PolymarketMapper()

    init(provider: TangemProvider<PolymarketEventSportsTarget>, baseURL: URL) {
        self.provider = provider
        self.baseURL = baseURL
    }
}

// MARK: - PolymarketEventSportsService protocol conformance

extension CommonPolymarketEventSportsService: PolymarketEventSportsService {
    func sports(eventSlug: String) async throws -> PolymarketEventSports {
        let target = PolymarketEventSportsTarget(baseURL: baseURL, eventSlug: eventSlug)

        do {
            let response = try await provider.requestPublisher(target).async()
            let filtered = try response.filterSuccessfulStatusAndRedirectCodes()
            let dto = try decoder.decode(PolymarketDTO.EventSports.self, from: filtered.data)

            return mapper.mapEventSports(dto)
        } catch let error as CancellationError {
            throw error
        } catch let error as MoyaError {
            throw CommonPolymarketAPIService.mapMoyaError(error, decoder: decoder)
        } catch {
            throw PolymarketAPIError.connection(underlying: error)
        }
    }
}
