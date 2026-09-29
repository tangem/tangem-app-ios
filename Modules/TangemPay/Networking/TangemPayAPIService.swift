//
//  TangemPayAPIService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
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

        if (500 ..< 600).contains(response.statusCode) {
            return .serverError(statusCode: response.statusCode)
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
    /// A non-401 server-side HTTP failure (e.g. 5xx). Keeps the status code so callers can tell
    /// a transient server error (like a 500 on challenge/token) apart from other failures.
    case serverError(statusCode: Int)
    case apiError(TangemPayAPIError)
    case decodingError(Error)
}

public struct TangemPayAPIError: Error, Decodable {
    public let correlationId: String?
    public let code: Int?
    public let message: String?

    public enum Code {
        public static let cardIssueActiveOrderExists = 140114
        public static let cardIssueOfferNotAvailable = 140115
        public static let cardIssueInsufficientBalance = 140116
        public static let cardIssueInvalidShippingAddress = 140126
        public static let cardIssueInvalidEmbossName = 140144

        public static let cardActivationInvalidCardData = 140127
        public static let cardActivationCardNotPhysical = 140128
        public static let cardActivationCardAlreadyActive = 140129
        public static let cardActivationCardNotReady = 140130
        public static let cardActivationActiveOrderExists = 140131

        public static let cardReissuePlasticInvalidSourceCard = 140132
        public static let cardReissuePlasticActiveOrderExists = 140133
        public static let cardReissuePlasticInsufficientBalance = 140134
        public static let cardReissuePlasticNotAvailable = 140135
        public static let cardReissuePlasticInvalidShippingAddress = 140136
        public static let cardReissuePlasticInvalidEmbossName = 140143
    }
}

public extension TangemPayAPIServiceError {
    var apiErrorCode: Int? {
        guard case .apiError(let apiError) = self else { return nil }

        return apiError.code
    }
}

private struct WrappedInResult<T: Decodable>: Decodable {
    let result: T
}

private struct WrappedInError<T: Decodable>: Decodable {
    let error: T
}
