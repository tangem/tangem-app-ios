//
//  TangemPayAPIService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Moya
import TangemNetworkUtils

public enum TangemPayAPIServiceError: Error {
    case moyaError(Error)
    case apiError(TangemPayAPIErrorWithStatusCode)
    case decodingError(Error)
}

public struct TangemPayAPIErrorWithStatusCode {
    public let statusCode: Int
    public let error: TangemPayAPIError
}

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

    func request<T: Decodable>(_ request: Target) async throws(TangemPayAPIServiceError) -> T {
        var response: Response
        do {
            response = try await provider.asyncRequest(request)
        } catch {
            throw .moyaError(error)
        }

        do {
            response = try response.filterSuccessfulStatusAndRedirectCodes()
        } catch {
            let errorResponse = try? decoder.decode(TangemPayAPIError.self, from: response.data)
            throw .apiError(
                .init(
                    statusCode: response.statusCode,
                    error: errorResponse ?? TangemPayAPIError(
                        code: nil,
                        correlationId: nil,
                        type: nil,
                        title: nil,
                        status: nil,
                        detail: nil,
                        instance: nil,
                        timestamp: nil
                    )
                )
            )
        }

        do {
            return try decoder.decode(T.self, from: response.data)
        } catch {
            throw .decodingError(error)
        }
    }
}

public struct TangemPayAPIError: Error, Decodable {
    public let code: String?
    public let correlationId: String?
    public let type: String?
    public let title: String?
    public let status: Int?
    public let detail: String?
    public let instance: String?
    public let timestamp: String?
}
