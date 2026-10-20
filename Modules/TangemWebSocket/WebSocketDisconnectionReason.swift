//
//  WebSocketDisconnectionReason.swift
//  TangemWebSocket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public enum WebSocketDisconnectionReason: Sendable {
    case insecureURL
    case serverTrustRejected
    case handshakeRejected(statusCode: Int)
    case handshakeTimeout
    case serverClosed(code: WebSocketCloseCode, reason: String?)
    case messageTooBig
    case keepaliveTimeout
    case connectionLost(underlying: any Error)
}
