//
//  PolymarketAPIError.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils

public enum PolymarketAPIError: Error, LocalizedError {
    case http(statusCode: Int, problemDetail: PolymarketProblemDetail?)

    case connection(underlying: Error)

    case decoding(field: String, value: String)

    public var errorDescription: String? {
        switch self {
        case .http(let statusCode, let problemDetail):
            return problemDetail?.message ?? "Polymarket API error \(statusCode)"
        case .connection(let underlying):
            return underlying.localizedDescription
        case .decoding(let field, let value):
            return "Polymarket API returned an unreadable \(field): \(value)"
        }
    }
}

public struct PolymarketProblemDetail: Decodable, Hashable, Sendable {
    public let type: String?
    public let title: String?
    public let status: Int?
    public let detail: String?
    public let instance: String?
    public let error: String?
    public let traceId: String?
    public let reason: String?

    public var message: String? {
        detail ?? error ?? title
    }

    public init(
        type: String? = nil,
        title: String? = nil,
        status: Int? = nil,
        detail: String? = nil,
        instance: String? = nil,
        error: String? = nil,
        traceId: String? = nil,
        reason: String? = nil
    ) {
        self.type = type
        self.title = title
        self.status = status
        self.detail = detail
        self.instance = instance
        self.error = error
        self.traceId = traceId
        self.reason = reason
    }
}

// MARK: - Retrying

public extension PolymarketAPIError {
    static let unauthorizedStatusCode = 401

    var isUnauthorized: Bool {
        guard case .http(let statusCode, _) = self else { return false }

        return statusCode == Self.unauthorizedStatusCode
    }

    var isTransient: Bool {
        switch self {
        case .http(let statusCode, _): (500 ... 599).contains(statusCode)
        case .connection(let underlying): !(underlying is DecodingError)
        case .decoding: false
        }
    }

    var isRetryable: Bool {
        guard case .http(let statusCode, _) = self else { return isTransient }

        return isTransient || Constants.retryableClientStatusCodes.contains(statusCode)
    }

    var isClientRefusal: Bool {
        guard case .http(let statusCode, _) = self else { return false }

        return (400 ..< 500).contains(statusCode)
    }

    var neverReachedTheServer: Bool {
        guard case .connection(let underlying) = self, let code = underlying.networkErrorCode else {
            return false
        }

        return Constants.unreachableCodes.contains(code)
    }
}

// MARK: - Constants

private extension PolymarketAPIError {
    enum Constants {
        static let retryableClientStatusCodes: Set<Int> = [408, 429]
        static let unreachableCodes: Set<URLError.Code> = [
            .notConnectedToInternet,
            .cannotFindHost,
            .cannotConnectToHost,
            .dnsLookupFailed,
            .secureConnectionFailed,
            .appTransportSecurityRequiresSecureConnection,
            .internationalRoamingOff,
            .dataNotAllowed,
        ]
    }
}
