//
//  PolymarketActivityFailure.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket

enum PolymarketActivityFailure: Hashable {
    case transient
    case rejected(statusCode: Int?)

    init(error: Error) {
        guard let apiError = error as? PolymarketAPIError else {
            self = .rejected(statusCode: nil)
            return
        }

        switch apiError {
        case _ where apiError.isTransient:
            self = .transient
        case .http(let statusCode, _):
            self = .rejected(statusCode: statusCode)
        case .connection, .decoding:
            self = .rejected(statusCode: nil)
        }
    }

    var isRetriedAutomatically: Bool {
        self == .transient
    }
}

// MARK: - Logging

extension PolymarketActivityFailure {
    static func log(_ error: Error, while action: String) {
        guard case PolymarketAPIError.http(let statusCode, let problemDetail) = error else {
            PolymarketLogger.error("Failed to \(action)", error: error)
            return
        }

        guard statusCode != Constants.tooManyRequestsStatusCode else { return }

        let traceId = problemDetail?.traceId ?? Constants.unknownTraceId

        switch statusCode {
        case Constants.forbiddenStatusCode:
            PolymarketLogger.error(
                "Failed to \(action): the deposit wallet does not belong to this wallet (403, traceId \(traceId))",
                error: error
            )
        default:
            PolymarketLogger.error("Failed to \(action): HTTP \(statusCode), traceId \(traceId)", error: error)
        }
    }

    private enum Constants {
        static let forbiddenStatusCode = 403
        static let tooManyRequestsStatusCode = 429
        static let unknownTraceId = "-"
    }
}
