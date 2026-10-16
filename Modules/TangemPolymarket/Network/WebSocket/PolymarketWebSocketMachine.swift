//
//  PolymarketWebSocketMachine.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemWebSocket

enum PolymarketWebSocketMachine {
    enum State: Sendable {
        case idle
        case connecting(attempt: Int)
        case connected
        case waitingToReconnect(attempt: Int)
        case stopped(PolymarketWebSocketDisconnection)
    }

    enum Event: Sendable {
        case connectRequested
        case disconnectRequested
        case opened
        case openFailed(PolymarketWebSocketDisconnection)
        case closed(PolymarketWebSocketDisconnection)
        case retryTimerFired
        case appWillEnterForeground
    }

    enum Effect: Hashable, Sendable {
        case openConnection
        case closeConnection(WebSocketCloseCode)
        case scheduleRetry(after: Duration)
        case cancelRetry
        case startKeepalive
        case stopKeepalive
    }

    static func transition(
        _ state: inout State,
        _ event: Event,
        random: (ClosedRange<Double>) -> Double = { Double.random(in: $0) }
    ) -> [Effect] {
        switch (state, event) {
        case (.idle, .connectRequested), (.stopped, .connectRequested):
            state = .connecting(attempt: 1)
            return [.openConnection]

        case (.waitingToReconnect(let attempt), .connectRequested),
             (.waitingToReconnect(let attempt), .appWillEnterForeground):
            state = .connecting(attempt: attempt + 1)
            return [.cancelRetry, .openConnection]

        case (.waitingToReconnect(let attempt), .retryTimerFired):
            state = .connecting(attempt: attempt + 1)
            return [.openConnection]

        case (.connecting, .opened):
            state = .connected
            return [.startKeepalive]

        case (.connecting(let attempt), .openFailed(let disconnection)):
            return retryOrStop(&state, attempt: attempt, after: disconnection, random: random)

        case (.connected, .closed(let disconnection)):
            return [.closeConnection(.goingAway), .stopKeepalive] + retryOrStop(&state, attempt: 1, after: disconnection, random: random)

        case (.connecting, .disconnectRequested):
            state = .idle
            return [.closeConnection(.normalClosure)]

        case (.connected, .disconnectRequested):
            state = .idle
            return [.closeConnection(.normalClosure), .stopKeepalive]

        case (.waitingToReconnect, .disconnectRequested):
            state = .idle
            return [.cancelRetry]

        case (.stopped, .disconnectRequested):
            state = .idle
            return []

        default:
            return []
        }
    }
}

// MARK: - Status

extension PolymarketWebSocketMachine.State {
    var status: PolymarketWebSocketConnectionStatus {
        switch self {
        case .idle:
            .idle
        case .connecting:
            .connecting
        case .connected:
            .connected
        case .waitingToReconnect:
            .waitingToReconnect
        case .stopped:
            .stopped
        }
    }
}

// MARK: - Private

private extension PolymarketWebSocketMachine {
    static func retryOrStop(
        _ state: inout State,
        attempt: Int,
        after disconnection: PolymarketWebSocketDisconnection,
        random: (ClosedRange<Double>) -> Double
    ) -> [Effect] {
        switch PolymarketWebSocketReconnectionDecision(after: disconnection) {
        case .stop:
            state = .stopped(disconnection)
            return []
        case .reconnect:
            let delay = PolymarketWebSocketBackoff.delay(forAttempt: attempt, random: random)
            state = .waitingToReconnect(attempt: attempt)
            return [.scheduleRetry(after: delay)]
        }
    }
}
