//
//  PolymarketWebSocketDisconnection.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemWebSocket

enum PolymarketWebSocketDisconnection: Error {
    case insecureURL
    case serverTrustRejected
    case handshakeRejected(statusCode: Int)
    case handshakeTimeout
    case serverClosed(code: WebSocketCloseCode, reason: String?)
    case messageTooBig
    case keepaliveTimeout
    case connectionLost(underlying: any Error)
}
