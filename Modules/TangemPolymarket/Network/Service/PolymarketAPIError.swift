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

    /// A field arrived in a shape the client cannot read. Reported rather than defaulted: a wrong amount is
    /// worse than a failed request.
    case decoding(field: String, value: String)

    public var errorDescription: String? {
        switch self {
        case .http(let statusCode, let problemDetail):
            return problemDetail?.detail ?? problemDetail?.title ?? "Polymarket API error \(statusCode)"
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
}
