//
//  PolymarketWebSocketReconnectionDecisionTests.swift
//  TangemPolymarketTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemWebSocket
@testable import TangemPolymarket

@Suite("Polymarket WebSocket reconnection decision")
struct PolymarketWebSocketReconnectionDecisionTests {
    @Test("Gives up for good only when another try cannot help", arguments: [
        Row("plain ws:// address", .stop) { .insecureURL },
        Row("untrusted certificate", .stop) { .serverTrustRejected },
        Row("handshake 401", .stop) { .handshakeRejected(statusCode: 401) },
        Row("handshake 403", .stop) { .handshakeRejected(statusCode: 403) },
        Row("handshake 404", .stop) { .handshakeRejected(statusCode: 404) },
        Row("message too big", .stop) { .messageTooBig },
        Row("closed for a policy violation", .stop) { .serverClosed(code: .policyViolation, reason: nil) },
        Row("handshake 503", .reconnect) { .handshakeRejected(statusCode: 503) },
        Row("handshake timeout", .reconnect) { .handshakeTimeout },
        Row("unanswered ping", .reconnect) { .keepaliveTimeout },
        Row("connection lost", .reconnect) { .connectionLost(underlying: URLError(.networkConnectionLost)) },
        Row("closed normally", .reconnect) { .serverClosed(code: .normalClosure, reason: nil) },
        Row("closed after a server error", .reconnect) { .serverClosed(code: .internalServerError, reason: "restart") },
    ])
    func decision(row: Row) {
        #expect(PolymarketWebSocketReconnectionDecision(after: row.disconnection()) == row.decision)
    }
}

// MARK: - Helpers

extension PolymarketWebSocketReconnectionDecisionTests {
    struct Row: Sendable, CustomTestStringConvertible {
        let testDescription: String
        let decision: PolymarketWebSocketReconnectionDecision
        let disconnection: @Sendable () -> PolymarketWebSocketDisconnection

        init(
            _ testDescription: String,
            _ decision: PolymarketWebSocketReconnectionDecision,
            disconnection: @escaping @Sendable () -> PolymarketWebSocketDisconnection
        ) {
            self.testDescription = testDescription
            self.decision = decision
            self.disconnection = disconnection
        }
    }
}
