//
//  PolymarketWebSocketChannel.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemWebSocket

protocol PolymarketWebSocketChannel: Sendable {
    associatedtype Topic: Hashable & Sendable
    associatedtype Update: Sendable
    associatedtype Value: Sendable

    var url: URL { get }
    var keepalive: PolymarketWebSocketConnectionManager.Keepalive { get }
    var subscribing: (any PolymarketWebSocketSubscribing<Topic>)? { get }

    func updates(from message: WebSocketMessage) throws -> [Update]
    func topic(of update: Update) -> Topic
    func value(applying update: Update, to previous: Value?) -> Value
}

protocol PolymarketWebSocketSubscribing<Topic>: Sendable {
    associatedtype Topic: Hashable & Sendable

    func subscribeMessage(for topics: Set<Topic>, isFirstOnConnection: Bool) throws -> WebSocketMessage
    func unsubscribeMessage(for topics: Set<Topic>) throws -> WebSocketMessage
}
