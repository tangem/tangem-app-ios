//
//  WebSocketMessage.swift
//  TangemWebSocket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// The WebSocket protocol defines only two kinds of data messages: text and binary.
/// See "Data Frames" in RFC 6455: https://datatracker.ietf.org/doc/html/rfc6455
enum WebSocketMessage: Sendable, Equatable {
    case text(String)
    case binary(Data)
}
