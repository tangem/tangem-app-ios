//
//  TangemPayAPIService.swift
//  TangemPay
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils

public enum ResponseFormat {
    case wrapped
    case plain
}

public struct TangemPayAPIService<Target: TargetType> {
    private let provider: TangemProvider<Target>
    private let decoder: JSONDecoder

    public init(
        provider: TangemProvider<Target>,
        decoder: JSONDecoder
    ) {
        self.provider = provider
        self.decoder = decoder
    }

    public func request<T: Decodable>(_ request: Target, format: ResponseFormat) async throws(TangemPayAPIServiceError) -> T {
        let response: Response
        do {
            response = try await provider.asyncRequest(request)
        } catch {
            throw .moyaError(error)
        }

        do {
            _ = try response.filterSuccessfulStatusAndRedirectCodes()
        } catch {
            throw parseError(response, format: format)
        }

        return try parseResult(response, format: format)
    }

    private func parseResult<T: Decodable>(_ response: Response, format: ResponseFormat) throws(TangemPayAPIServiceError) -> T {
        do {
            switch format {
            case .wrapped:
                return try decoder.decode(WrappedInResult<T>.self, from: response.data).result
            case .plain:
                return try decoder.decode(T.self, from: response.data)
            }
        } catch {
            throw .decodingError(error)
        }
    }

    private func parseError(_ response: Response, format: ResponseFormat) -> TangemPayAPIServiceError {
        if response.statusCode == 401 {
            return .unauthorized
        }

        do {
            switch format {
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

public enum TangemPayAPIServiceError: Error {
    case moyaError(Error)
    case unauthorized
    case apiError(TangemPayAPIError)
    case decodingError(Error)
}

public struct TangemPayAPIError: Error, Decodable {
    public let correlationId: String
}

private struct WrappedInResult<T: Decodable>: Decodable {
    let result: T
}

private struct WrappedInError<T: Decodable>: Decodable {
    let error: T
}
