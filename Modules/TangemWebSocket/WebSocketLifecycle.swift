//
//  WebSocketLifecycle.swift
//  TangemWebSocket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public enum WebSocketLifecycle: Hashable, Sendable {
    case persistent
    case onDemand(idleTimeout: Duration)
}
