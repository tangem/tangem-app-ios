//
//  PolymarketWebSocketReconnectionDecision.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemWebSocket

enum PolymarketWebSocketReconnectionDecision: Hashable, Sendable {
    case reconnect
    case stop

    init(after disconnection: PolymarketWebSocketDisconnection) {
        switch disconnection {
        case .insecureURL, .serverTrustRejected, .messageTooBig:
            self = .stop
        case .handshakeRejected(let statusCode) where Constants.permanentHandshakeRejectionStatusCodes.contains(statusCode):
            self = .stop
        case .serverClosed(.policyViolation, _):
            self = .stop
        case .handshakeRejected, .serverClosed, .handshakeTimeout, .keepaliveTimeout, .connectionLost:
            self = .reconnect
        }
    }
}

// MARK: - Constants

private extension PolymarketWebSocketReconnectionDecision {
    enum Constants {
        static let permanentHandshakeRejectionStatusCodes: Set<Int> = [401, 403, 404]
    }
}
