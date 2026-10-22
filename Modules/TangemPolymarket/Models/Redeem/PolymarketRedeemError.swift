//
//  PolymarketRedeemError.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemMacro

@CaseFlagable
public enum PolymarketRedeemError: Error {
    case badRequest(detail: String?)
    case unauthorized
    case notFound
    case nothingToRedeem
    case relayerRejected(detail: String?)
    case upstreamUnavailable(detail: String?)
    case cancelled
    case other(PolymarketAPIError)
}

// MARK: - Mapping

extension PolymarketRedeemError: PolymarketRelayedError {
    public init(apiError: PolymarketAPIError) {
        guard case .http(let statusCode, let problemDetail) = apiError else {
            self = .other(apiError)
            return
        }

        let detail = problemDetail?.detail

        switch statusCode {
        case 400: self = .badRequest(detail: detail)
        case 401: self = .unauthorized
        case 404: self = .notFound
        case 422: self = .relayerRejected(detail: detail)
        case 502: self = .upstreamUnavailable(detail: detail)
        default: self = .other(apiError)
        }
    }
}

// MARK: - Asking for the redeem calls

extension PolymarketRedeemError {
    static func forRedeemCall(_ error: PolymarketRedeemError) -> PolymarketRedeemError {
        guard case .other(.http(statusCode: Constants.conflictStatusCode, _)) = error else {
            return error
        }

        return .nothingToRedeem
    }
}

private extension PolymarketRedeemError {
    enum Constants {
        static let conflictStatusCode = 409
    }
}
