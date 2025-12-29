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
    private let decoder: JSONDecoder

    init(
        provider: TangemProvider<Target>,
        decoder: JSONDecoder
    ) {
        self.provider = provider
        self.decoder = decoder
    }

    func request<T: Decodable>(_ request: Target, wrapped: Bool) async throws(TangemPayAPIServiceError) -> T {
        let response = try await executeRequest(request)

        do {
            _ = try response.filterSuccessfulStatusAndRedirectCodes()
        } catch {
            throw parseError(response, wrapped: wrapped)
        }

        return try parseResponse(response, wrapped: wrapped)
    }

    private func executeRequest(_ request: Target) async throws(TangemPayAPIServiceError) -> Response {
        do {
            return try await provider.asyncRequest(request)
        } catch {
            throw .moyaError(error)
        }
    }

    private func parseError(_ response: Response, wrapped: Bool) -> TangemPayAPIServiceError {
        if response.statusCode == 401 {
            return .unauthorized
        }

        do {
            if wrapped {
                let error = try decoder.decode(WrappedInError<VisaAPIError>.self, from: response.data).error
                return .apiError(.visa(error))
            } else {
                let error = try decoder.decode(TangemPayAPIError.self, from: response.data)
                return .apiError(.tangemPay(error))
            }
        } catch {
            return .decodingError(error)
        }
    }

    private func parseResponse<T: Decodable>(_ response: Response, wrapped: Bool) throws(TangemPayAPIServiceError) -> T {
        do {
            if wrapped {
                return try decoder.decode(WrappedInResult<T>.self, from: response.data).result
            } else {
                return try decoder.decode(T.self, from: response.data)
            }
        } catch {
            throw .decodingError(error)
        }
    }
}

public enum TangemPayAPIServiceError: Error {
    public enum Kind {
        case tangemPay(TangemPayAPIError)
        case visa(VisaAPIError)
    }

    case moyaError(Error)
    case unauthorized
    case apiError(Kind)
    case decodingError(Error)
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

private struct WrappedInResult<T: Decodable>: Decodable {
    let result: T
}

private struct WrappedInError<T: Decodable>: Decodable {
    let error: T
}
