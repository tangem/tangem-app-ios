//
//  WebSocketConnection.swift
//  TangemWebSocket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public protocol WebSocketConnection: AnyObject, Sendable {
    func send(_ message: WebSocketMessage) async throws(WebSocketTransportError)
    func receive() async throws(WebSocketTransportError) -> WebSocketMessage
    func ping() async throws(WebSocketTransportError)
    func close(code: WebSocketCloseCode, reason: String?)
}
