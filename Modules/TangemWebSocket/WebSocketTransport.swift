//
//  WebSocketTransport.swift
//  TangemWebSocket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import Foundation

public protocol WebSocketTransport: Sendable {
    func connect(to url: URL, headers: [String: String]) async throws(WebSocketTransportError) -> any WebSocketConnection
}
