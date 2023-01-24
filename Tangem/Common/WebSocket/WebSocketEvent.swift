//
//  WebSocketEvent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

extension WebSocket {
    enum WebSocketEvent {
        case connected
        case disconnected(URLSessionWebSocketTask.CloseCode)
        case messageReceived(String)
        case messageSent(String)
        case pingSent
        case pongReceived
        case connnectionError(Error)
    }
}
