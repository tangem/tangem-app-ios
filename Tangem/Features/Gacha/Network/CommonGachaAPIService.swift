//
//  CommonGachaAPIService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils

final class CommonGachaAPIService {
    private let provider: TangemProvider<GachaAPITarget>
    private let baseURL: URL

    private let decoder = JSONDecoder()

    init(provider: TangemProvider<GachaAPITarget>, baseURL: URL) {
        self.provider = provider
        self.baseURL = baseURL
    }
}

// MARK: - GachaAPIService

extension CommonGachaAPIService: GachaAPIService {
    func categories() async throws -> GachaDTO.MachineCategoriesResponse {
        try await request(.categories)
    }

    func machines(request: GachaMachinesRequest) async throws -> GachaDTO.MachinesResponse {
        try await self.request(.machines(request))
    }

    func machine(externalID: String) async throws -> GachaDTO.Machine {
        try await request(.machine(externalID: externalID))
    }
}

// MARK: - Private

private extension CommonGachaAPIService {
    func request<T: Decodable>(_ target: GachaAPITarget.Target) async throws -> T {
        let request = GachaAPITarget(baseURL: baseURL, target: target)

        do {
            let response = try await provider.asyncRequest(request)
            let filtered = try response.filterSuccessfulStatusAndRedirectCodes()
            return try decoder.decode(T.self, from: filtered.data)
        } catch let error as CancellationError {
            throw error
        } catch let error as DecodingError {
            throw GachaAPIError.decoding(error)
        } catch let error as MoyaError {
            throw Self.mapMoyaError(error)
        } catch {
            throw GachaAPIError.connection(underlying: error)
        }
    }
}

// MARK: - Error mapping

extension CommonGachaAPIService {
    static func mapMoyaError(_ error: MoyaError) -> GachaAPIError {
        guard let response = error.response else {
            // Forward the underlying transport error so cancellation / network codes stay inspectable.
            return .connection(underlying: error.underlyingError ?? error)
        }

        return .http(statusCode: response.statusCode, body: response.data)
    }
}
