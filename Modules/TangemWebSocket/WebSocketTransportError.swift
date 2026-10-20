//
//  WebSocketTransportError.swift
//  TangemWebSocket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
public import protocol TangemFoundation.UniversalError

public enum WebSocketTransportError: Error {
    case insecureURL
    case serverTrustRejected
    case handshakeRejected(statusCode: Int)
    case closed(code: WebSocketCloseCode, reason: String?)
    case messageTooBig
    case connectionFailed(underlying: any Error)
    case cancelled
}

// MARK: - UniversalError

extension WebSocketTransportError: UniversalError {
    public var errorCode: Int {
        switch self {
        case .insecureURL:
            113000000
        case .serverTrustRejected:
            113000001
        case .handshakeRejected:
            113000002
        case .closed:
            113000003
        case .messageTooBig:
            113000004
        case .connectionFailed:
            113000005
        case .cancelled:
            113000006
        }
    }
}
