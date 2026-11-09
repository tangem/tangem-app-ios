//
//  PolymarketWebSocketMachineTests.swift
//  TangemPolymarketTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemWebSocket
@testable import TangemPolymarket

@Suite("Polymarket WebSocket machine")
struct PolymarketWebSocketMachineTests {
    @Test("Failed opens in a row wait longer each time, a dropped live connection starts again from the shortest wait")
    func retryWaitGrowsOnlyWhileOpeningFails() {
        var machine = MachineDriver()

        #expect(machine.send(.connectRequested) == [.openConnection])
        #expect(machine.send(.openFailed(.handshakeTimeout)) == [.scheduleRetry(after: .seconds(1))])
        #expect(machine.send(.retryTimerFired) == [.openConnection])
        #expect(machine.send(.openFailed(.handshakeTimeout)) == [.scheduleRetry(after: .seconds(2))])
        #expect(machine.send(.retryTimerFired) == [.openConnection])
        #expect(machine.send(.openFailed(.handshakeTimeout)) == [.scheduleRetry(after: .seconds(4))])
        #expect(machine.send(.retryTimerFired) == [.openConnection])
        #expect(machine.send(.opened) == [.startKeepalive])
        _ = machine.send(.messageReceived)

        #expect(machine.send(.closed(.keepaliveTimeout)).contains(.scheduleRetry(after: .seconds(1))))
        #expect(machine.status == .waitingToReconnect)
    }

    @Test("A connection the server closes before sending anything counts as a failed attempt, so a flapping server is retried less and less often")
    func closeBeforeTheFirstMessageKeepsGrowingTheWait() {
        var machine = MachineDriver()
        _ = machine.send(.connectRequested)

        for seconds in [1, 2, 4, 8] {
            _ = machine.send(.opened)
            #expect(machine.send(.closed(.serverClosed(code: .normalClosure, reason: nil))).contains(.scheduleRetry(after: .seconds(seconds))))
            _ = machine.send(.retryTimerFired)
        }
    }

    @Test("Coming back to the app skips the rest of a retry wait and leaves a live connection alone")
    func foregroundSkipsTheRetryWait() {
        var machine = MachineDriver.connected()

        #expect(machine.send(.appWillEnterForeground).isEmpty)
        #expect(machine.status == .connected)

        _ = machine.send(.closed(.connectionLost(underlying: URLError(.networkConnectionLost))))

        #expect(machine.send(.appWillEnterForeground).contains(.openConnection))
        #expect(machine.status == .connecting)
    }

    @Test("A hopeless failure stops reconnecting, coming back to the app does not revive it, a new connect request does")
    func stopWaitsForANewConnectRequest() {
        var machine = MachineDriver()
        _ = machine.send(.connectRequested)

        #expect(machine.send(.openFailed(.handshakeRejected(statusCode: 404))).isEmpty)
        #expect(machine.status == .stopped)
        #expect(machine.send(.appWillEnterForeground).isEmpty)
        #expect(machine.status == .stopped)

        #expect(machine.send(.connectRequested) == [.openConnection])
        #expect(machine.status == .connecting)
    }

    @Test("Nothing reconnects after leaving during a retry wait, even if the retry timer still fires")
    func leavingDuringARetryWaitReconnectsNothing() {
        var machine = MachineDriver.connected()
        _ = machine.send(.closed(.keepaliveTimeout))

        _ = machine.send(.disconnectRequested)

        #expect(machine.send(.retryTimerFired).isEmpty)
        #expect(machine.status == .idle)
    }
}

// MARK: - Helpers

private struct MachineDriver {
    private var state: PolymarketWebSocketMachine.State = .idle

    var status: PolymarketWebSocketConnectionStatus {
        state.status
    }

    static func connected() -> MachineDriver {
        var machine = MachineDriver()
        _ = machine.send(.connectRequested)
        _ = machine.send(.opened)
        _ = machine.send(.messageReceived)
        return machine
    }

    mutating func send(_ event: PolymarketWebSocketMachine.Event) -> [PolymarketWebSocketMachine.Effect] {
        PolymarketWebSocketMachine.transition(&state, event, random: { _ in 1 })
    }
}
