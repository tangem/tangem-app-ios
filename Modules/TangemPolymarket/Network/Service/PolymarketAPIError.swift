//
//  PolymarketAPIError.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

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

    public var message: String? {
        detail ?? error ?? title
    }

    public init(
        type: String? = nil,
        title: String? = nil,
        status: Int? = nil,
        detail: String? = nil,
        instance: String? = nil,
        error: String? = nil
    ) {
        self.type = type
        self.title = title
        self.status = status
        self.detail = detail
        self.instance = instance
        self.error = error
    }
}

// MARK: - Retrying

public extension PolymarketAPIError {
    var isTransient: Bool {
        switch self {
        case .http(let statusCode, _): (500 ... 599).contains(statusCode)
        case .connection(let underlying): !(underlying is DecodingError)
        case .decoding: false
        }
    }
}
