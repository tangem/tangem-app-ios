//
//  WebSocketReconnectionDecision.swift
//  TangemWebSocket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public enum WebSocketReconnectionDecision: Hashable, Sendable {
    case reconnect
    case stop
}

public extension WebSocketReconnectionDecision {
    static func `default`(for reason: WebSocketDisconnectionReason) -> WebSocketReconnectionDecision {
        switch reason {
        case .insecureURL, .serverTrustRejected, .messageTooBig:
            .stop
        case .handshakeRejected(let statusCode):
            Constants.permanentHandshakeRejectionStatusCodes.contains(statusCode) ? .stop : .reconnect
        case .handshakeTimeout, .serverClosed, .keepaliveTimeout, .connectionLost:
            .reconnect
        }
    }
}

// MARK: - Constants

private extension WebSocketReconnectionDecision {
    enum Constants {
        static let permanentHandshakeRejectionStatusCodes: Set<Int> = [401, 403, 404]
    }
}
