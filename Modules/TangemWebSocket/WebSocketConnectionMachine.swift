//
//  WebSocketConnectionMachine.swift
//  TangemWebSocket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum WebSocketConnectionMachine {
    enum State: Sendable {
        case idle
        case connecting(attempt: Int)
        case connected
        case waitingToReconnect(attempt: Int, delay: Duration)
        case stopped(WebSocketDisconnectionReason)
    }

    enum Event: Sendable {
        case connectRequested
        case disconnectRequested
        case opened
        case openFailed(WebSocketDisconnectionReason)
        case closed(WebSocketDisconnectionReason)
        case retryTimerFired
        case idleTimerFired
        case activity
        case appWillEnterForeground
    }

    enum Effect: Hashable, Sendable {
        case openConnection
        case closeConnection(WebSocketCloseCode)
        case scheduleRetry(after: Duration)
        case cancelRetry
        case startKeepalive
        case stopKeepalive
        case restartIdleTimer
        case cancelIdleTimer
        case checkConnectionNow
    }

    struct Configuration: Sendable {
        let lifecycle: WebSocketLifecycle
        let backoff: WebSocketBackoff
        let reconnectionRule: @Sendable (WebSocketDisconnectionReason) -> WebSocketReconnectionDecision
    }

    static func transition(
        _ state: inout State,
        _ event: Event,
        configuration: Configuration,
        random: (ClosedRange<Double>) -> Double = { Double.random(in: $0) }
    ) -> [Effect] {
        switch configuration.lifecycle {
        case .persistent:
            persistentTransition(&state, event, configuration: configuration, random: random)
        case .onDemand:
            onDemandTransition(&state, event)
        }
    }
}

// MARK: - Status

extension WebSocketConnectionMachine.State {
    var status: WebSocketConnectionStatus {
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

// MARK: - Persistent

private extension WebSocketConnectionMachine {
    static func persistentTransition(
        _ state: inout State,
        _ event: Event,
        configuration: Configuration,
        random: (ClosedRange<Double>) -> Double
    ) -> [Effect] {
        switch (state, event) {
        case (.idle, .connectRequested), (.stopped, .connectRequested):
            state = .connecting(attempt: 1)
            return [.openConnection]

        case (.waitingToReconnect(let attempt, _), .connectRequested),
             (.waitingToReconnect(let attempt, _), .appWillEnterForeground):
            state = .connecting(attempt: attempt + 1)
            return [.cancelRetry, .openConnection]

        case (.waitingToReconnect(let attempt, _), .retryTimerFired):
            state = .connecting(attempt: attempt + 1)
            return [.openConnection]

        case (.connecting, .opened):
            state = .connected
            return [.startKeepalive]

        case (.connecting(let attempt), .openFailed(let reason)):
            return retryOrStop(&state, attempt: attempt, after: reason, configuration: configuration, random: random)

        case (.connected, .closed(let reason)):
            return [.closeConnection(.goingAway), .stopKeepalive] + retryOrStop(&state, attempt: 1, after: reason, configuration: configuration, random: random)

        case (.connected, .appWillEnterForeground):
            return [.checkConnectionNow]

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

    static func retryOrStop(
        _ state: inout State,
        attempt: Int,
        after reason: WebSocketDisconnectionReason,
        configuration: Configuration,
        random: (ClosedRange<Double>) -> Double
    ) -> [Effect] {
        switch configuration.reconnectionRule(reason) {
        case .stop:
            state = .stopped(reason)
            return []
        case .reconnect:
            let delay = configuration.backoff.delay(forAttempt: attempt, random: random)
            state = .waitingToReconnect(attempt: attempt, delay: delay)
            return [.scheduleRetry(after: delay)]
        }
    }
}

// MARK: - On demand

private extension WebSocketConnectionMachine {
    static func onDemandTransition(_ state: inout State, _ event: Event) -> [Effect] {
        switch (state, event) {
        case (.idle, .connectRequested), (.stopped, .connectRequested):
            state = .connecting(attempt: 1)
            return [.openConnection]

        case (.connecting, .opened):
            state = .connected
            return [.startKeepalive, .restartIdleTimer]

        case (.connecting, .openFailed(let reason)):
            state = .stopped(reason)
            return []

        case (.connected, .activity):
            return [.restartIdleTimer]

        case (.connected, .idleTimerFired):
            state = .idle
            return [.closeConnection(.normalClosure), .stopKeepalive]

        case (.connected, .closed(let reason)):
            state = .stopped(reason)
            return [.closeConnection(.goingAway), .stopKeepalive, .cancelIdleTimer]

        case (.connecting, .disconnectRequested):
            state = .idle
            return [.closeConnection(.normalClosure)]

        case (.connected, .disconnectRequested):
            state = .idle
            return [.closeConnection(.normalClosure), .stopKeepalive, .cancelIdleTimer]

        case (.stopped, .disconnectRequested):
            state = .idle
            return []

        default:
            return []
        }
    }
}
