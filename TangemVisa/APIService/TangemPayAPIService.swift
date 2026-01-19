//
//  TangemPayAPIService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Moya
import TangemNetworkUtils

public struct TangemPayAPIService<Target: TargetType> {
    private let provider: TangemProvider<Target>
    private let decoder: JSONDecoder
    private let responseFormat: ResponseFormat

    public init(
        provider: TangemProvider<Target>,
        decoder: JSONDecoder,
        responseFormat: ResponseFormat
    ) {
        self.provider = provider
        self.decoder = decoder
        self.responseFormat = responseFormat
    }

    public func request<T: Decodable>(_ request: Target) async throws(TangemPayAPIServiceError) -> T {
        let response: Response
        do {
            response = try await provider.asyncRequest(request)
        } catch {
            throw .moyaError(error)
        }

        do {
            _ = try response.filterSuccessfulStatusAndRedirectCodes()
        } catch {
            throw parseError(response)
        }

        return try parseResult(response)
    }

    private func parseResult<T: Decodable>(_ response: Response) throws(TangemPayAPIServiceError) -> T {
        do {
            switch responseFormat {
            case .wrapped:
                return try decoder.decode(WrappedInResult<T>.self, from: response.data).result
            case .plain:
                return try decoder.decode(T.self, from: response.data)
            }
        } catch {
            throw .decodingError(error)
        }
    }

    private func parseError(_ response: Response) -> TangemPayAPIServiceError {
        if response.statusCode == 401 {
            return .unauthorized
        }

        do {
            switch responseFormat {
            case .wrapped:
                let error = try decoder.decode(WrappedInError<TangemPayAPIError>.self, from: response.data).error
                return .apiError(error)
            case .plain:
                let error = try decoder.decode(TangemPayAPIError.self, from: response.data)
                return .apiError(error)
            }
        } catch {
            return .decodingError(error)
        }
    }
}

public extension TangemPayAPIService {
    enum ResponseFormat {
        /// Wraps responses in a structured envelope.
        /// - Success: `{ "result": <response_data> }`
        /// - Failure: `{ "error": <error_details> }`
        case wrapped

        /// Returns the response data directly without any wrapper.
        case plain
    }
}

public enum TangemPayAPIServiceError: Error {
    case moyaError(Error)
    case unauthorized
    case apiError(TangemPayAPIError)
    case decodingError(Error)
}

public struct TangemPayAPIError: Error, Decodable {
    public let correlationId: String?
}

private struct WrappedInResult<T: Decodable>: Decodable {
    let result: T
}

private struct WrappedInError<T: Decodable>: Decodable {
    let error: T
}
