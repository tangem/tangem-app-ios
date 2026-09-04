//
//  CommonCollectiblesAPIService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils

final class CommonCollectiblesAPIService {
    private let provider: TangemProvider<CollectiblesAPITarget>
    private let baseURL: URL

    private let decoder = JSONDecoder()

    init(provider: TangemProvider<CollectiblesAPITarget>, baseURL: URL) {
        self.provider = provider
        self.baseURL = baseURL
    }
}

// MARK: - CollectiblesAPIService

extension CommonCollectiblesAPIService: CollectiblesAPIService {
    func categories() async throws -> CollectiblesDTO.MachineCategoriesResponse {
        try await request(.categories)
    }

    func machines(request: CollectiblesMachinesRequest) async throws -> CollectiblesDTO.MachinesResponse {
        try await self.request(.machines(request))
    }

    func machine(externalID: String) async throws -> CollectiblesDTO.Machine {
        try await request(.machine(externalID: externalID))
    }
}

// MARK: - Private

private extension CommonCollectiblesAPIService {
    func request<T: Decodable>(_ target: CollectiblesAPITarget.Target) async throws -> T {
        let request = CollectiblesAPITarget(baseURL: baseURL, target: target)

        do {
            let response = try await provider.asyncRequest(request)
            let filtered = try response.filterSuccessfulStatusAndRedirectCodes()
            return try decoder.decode(T.self, from: filtered.data)
        } catch let error as CancellationError {
            throw error
        } catch let error as DecodingError {
            throw CollectiblesAPIError.decoding(error)
        } catch let error as MoyaError {
            throw Self.mapMoyaError(error)
        } catch {
            throw CollectiblesAPIError.connection(underlying: error)
        }
    }
}

// MARK: - Error mapping

extension CommonCollectiblesAPIService {
    static func mapMoyaError(_ error: MoyaError) -> CollectiblesAPIError {
        guard let response = error.response else {
            // Forward the underlying transport error so cancellation / network codes stay inspectable.
            return .connection(underlying: error.underlyingError ?? error)
        }

        return .http(statusCode: response.statusCode, body: response.data)
    }
}
