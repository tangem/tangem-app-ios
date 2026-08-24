//
//  PolymarketWalletError.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemMacro

@CaseFlagable
public enum PolymarketWalletError: Error {
    case badRequest(detail: String?)
    case unauthorized
    case conflict(detail: String?)
    case relayerRejected(detail: String?)
    case upstreamUnavailable(detail: String?)
    case cancelled
    case other(PolymarketAPIError)
}

// MARK: - Mapping

public extension PolymarketWalletError {
    init(apiError: PolymarketAPIError) {
        guard case .http(let statusCode, let problemDetail) = apiError else {
            self = .other(apiError)
            return
        }

        let detail = problemDetail?.detail

        switch statusCode {
        case 400: self = .badRequest(detail: detail)
        case 401: self = .unauthorized
        case 409: self = .conflict(detail: detail)
        case 422: self = .relayerRejected(detail: detail)
        case 502: self = .upstreamUnavailable(detail: detail)
        default: self = .other(apiError)
        }
    }
}
