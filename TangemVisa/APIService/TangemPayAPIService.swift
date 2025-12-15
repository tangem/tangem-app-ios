//
//  TangemPayAPIService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Moya
import TangemNetworkUtils

struct TangemPayAPIService<Target: TargetType> {
    private let provider: TangemProvider<Target>
    private var decoder: JSONDecoder

    init(
        provider: TangemProvider<Target>,
        decoder: JSONDecoder
    ) {
        self.provider = provider
        self.decoder = decoder
    }

    func request<T: Decodable>(_ request: Target) async throws -> T {
        var response = try await provider.asyncRequest(request)

        do {
            response = try response.filterSuccessfulStatusAndRedirectCodes()
        } catch {
            let errorResponse = try decoder.decode(TangemPayAPIErrorResponse.self, from: response.data)
            throw errorResponse
        }

        return try decoder.decode(T.self, from: response.data)
    }
}

public struct TangemPayAPIErrorResponse: Error, Decodable {
    public let code: String?
    public let correlationId: String?
    public let type: String?
    public let title: String?
    public let status: Int?
    public let detail: String?
    public let instance: String?
    public let timestamp: String?
}
