//
//  PolymarketRelayedRequest.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemFoundation
import TangemNetworkUtils

protocol PolymarketRelayedError: Error {
    static var cancelled: Self { get }

    init(apiError: PolymarketAPIError)
}

enum PolymarketRelayedRequest {
    static func perform<Target: Moya.TargetType, Response: Decodable, Failure: PolymarketRelayedError>(
        _ request: Target,
        provider: TangemProvider<Target>,
        decoder: JSONDecoder,
        failure: Failure.Type = Failure.self
    ) async throws(Failure) -> Response {
        do {
            let response = try await provider.requestPublisher(request).async()
            let filtered = try response.filterSuccessfulStatusAndRedirectCodes()
            return try decoder.decode(Response.self, from: filtered.data)
        } catch is CancellationError {
            throw Failure.cancelled
        } catch let error as MoyaError {
            throw Failure(apiError: CommonPolymarketAPIService.mapMoyaError(error, decoder: decoder))
        } catch let error as DecodingError {
            throw Failure(apiError: .decoding(field: String(describing: Response.self), value: "\(error)"))
        } catch {
            throw Failure(apiError: .connection(underlying: error))
        }
    }
}
