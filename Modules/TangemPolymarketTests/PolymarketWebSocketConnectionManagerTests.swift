//
//  PolymarketWebSocketConnectionManagerTests.swift
//  TangemPolymarketTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
import TangemWebSocket
@testable import TangemPolymarket

@Suite("Polymarket WebSocket connection manager", .timeLimit(.minutes(1)))
struct PolymarketWebSocketConnectionManagerTests {
    @Test("A connection the server closes is opened again once the retry wait is over, and frames keep coming")
    func serverCloseReconnectsAfterTheRetryWait() async throws {
        let env = await makeSUT()
        let first = try await env.connect()

        first.receive("before")
        #expect(try await env.messages.values.element(at: 0) == .text("before"))

        first.closeByServer(code: .normalClosure)
        #expect(try await env.statuses.values.element(at: 2) == .waitingToReconnect)
        #expect(try await first.closeCodes.element(at: 0) == .goingAway)

        let retryWait = try await env.delayProvider.retryWaits.element(at: 0)
        #expect(env.transport.connections.elements.count == 1)

        retryWait.release()
        let second = try await env.transport.connections.element(at: 1)
        #expect(try await env.statuses.values.element(at: 4) == .connected)

        second.receive("after")
        #expect(try await env.messages.values.element(at: 1) == .text("after"))
    }

    @Test(
        "A connection that brought a data frame counts as healthy and its drop is retried after the shortest wait, a reply to our ping alone does not count",
        arguments: zip([Constants.dataFrame, Constants.keepaliveReply], [1.0, 2.0])
    )
    func dropAfterAFrameRestartsFromTheShortestWait(frame: String, secondRetrySeconds: TimeInterval) async throws {
        let env = await makeSUT()
        let first = try await env.connect()

        first.closeByServer(code: .normalClosure)
        let firstRetry = try await env.delayProvider.retryWaits.element(at: 0)
        firstRetry.release()

        let second = try await env.transport.connections.element(at: 1)
        second.receive(frame)
        #expect(try await env.messages.values.element(at: 0) == .text(frame))
        second.closeByServer(code: .normalClosure)

        #expect(firstRetry.seconds == 1)
        #expect(try await env.delayProvider.retryWaits.element(at: 1).seconds == secondRetrySeconds)
    }

    @Test("A server closing for a policy violation is not reconnected until a new connect request")
    func policyViolationStopsUntilANewConnectRequest() async throws {
        let env = await makeSUT()
        let first = try await env.connect()

        first.closeByServer(code: .policyViolation)
        #expect(try await env.statuses.values.element(at: 2) == .stopped)

        await env.sut.connect()
        try await env.transport.connections.element(at: 1)
        #expect(try await env.statuses.values.element(at: 4) == .connected)
    }

    @Test("A busy server rejecting the handshake is asked again until it lets us in")
    func busyServerHandshakeIsRetried() async throws {
        let env = await makeSUT(rejectedHandshakes: [503, 503])

        await env.sut.connect()
        #expect(try await env.statuses.values.element(at: 1) == .waitingToReconnect)

        try await env.delayProvider.retryWaits.element(at: 0).release()
        #expect(try await env.statuses.values.element(at: 3) == .waitingToReconnect)

        try await env.delayProvider.retryWaits.element(at: 1).release()
        #expect(try await env.statuses.values.element(at: 5) == .connected)
        #expect(env.transport.connections.elements.count == 1)
    }

    @Test("Pings go on while they are sent, a ping that cannot be sent drops the connection and reconnects")
    func failedPingReconnects() async throws {
        let env = await makeSUT()
        let connection = try await env.connect()

        try await env.delayProvider.keepaliveWaits.element(at: 0).release()
        try await env.delayProvider.keepaliveWaits.element(at: 1)
        #expect(env.statuses.values.elements == [.connecting, .connected])

        connection.failPings()
        try await env.delayProvider.keepaliveWaits.element(at: 1).release()

        #expect(try await env.statuses.values.element(at: 2) == .waitingToReconnect)
        #expect(try await connection.closeCodes.element(at: 0) == .goingAway)
    }
}

// MARK: - Helpers

private extension PolymarketWebSocketConnectionManagerTests {
    func makeSUT(rejectedHandshakes: [Int] = []) async -> Environment {
        let transport = WebSocketTransportSpy(rejectedHandshakes: rejectedHandshakes)
        let delayProvider = DelayProviderSpy(keepaliveInterval: Constants.keepaliveInterval)

        let sut = PolymarketWebSocketConnectionManager(
            url: Constants.url,
            keepalive: .protocolPing(interval: Constants.keepaliveInterval, timeout: Constants.pingTimeout),
            isKeepaliveReply: { $0 == .text(Constants.keepaliveReply) },
            transport: transport,
            delayProvider: delayProvider,
            notificationCenter: NotificationCenter(),
            random: { _ in 1 }
        )

        return Environment(
            sut: sut,
            transport: transport,
            delayProvider: delayProvider,
            statuses: StreamReaderSpy(stream: await sut.statusChanges),
            messages: StreamReaderSpy(stream: await sut.messages)
        )
    }

    struct Environment {
        let sut: PolymarketWebSocketConnectionManager
        let transport: WebSocketTransportSpy
        let delayProvider: DelayProviderSpy
        let statuses: StreamReaderSpy<PolymarketWebSocketConnectionStatus>
        let messages: StreamReaderSpy<WebSocketMessage>

        func connect() async throws -> WebSocketConnectionSpy {
            await sut.connect()
            let connection = try await transport.connections.element(at: 0)
            try await statuses.values.element(at: 1)
            return connection
        }
    }

    enum Constants {
        static let url = URL(string: "wss://manager.test")!
        static let keepaliveInterval: Duration = .seconds(3600)
        static let pingTimeout: Duration = .seconds(3600)
        static let dataFrame = "frame"
        static let keepaliveReply = "PONG"
    }
}

// MARK: - Doubles

private final class DelayProviderSpy: PollDelayProvider, Sendable {
    let keepaliveWaits = AsyncRecord<ParkedWait>()
    let retryWaits = AsyncRecord<ParkedWait>()

    private let keepaliveSeconds: TimeInterval

    init(keepaliveInterval: Duration) {
        keepaliveSeconds = keepaliveInterval / .seconds(1)
    }

    func wait(for seconds: TimeInterval) async throws {
        let wait = ParkedWait(seconds: seconds)

        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                wait.park(continuation)
                (seconds == keepaliveSeconds ? keepaliveWaits : retryWaits).append(wait)
            }
        } onCancel: {
            wait.cancel()
        }
    }
}

private final class ParkedWait: Sendable {
    let seconds: TimeInterval

    private let state = OSAllocatedUnfairLock(initialState: State.pending)

    init(seconds: TimeInterval) {
        self.seconds = seconds
    }

    func park(_ continuation: CheckedContinuation<Void, any Error>) {
        let earlyResult = state.withLock { state -> Result<Void, any Error>? in
            switch state {
            case .pending:
                state = .parked(continuation)
                return nil
            case .parked, .finished:
                return .failure(CancellationError())
            }
        }

        if let earlyResult {
            continuation.resume(with: earlyResult)
        }
    }

    func release() {
        finish()?.resume()
    }

    func cancel() {
        finish()?.resume(throwing: CancellationError())
    }

    private func finish() -> CheckedContinuation<Void, any Error>? {
        state.withLock { state in
            defer { state = .finished }

            guard case .parked(let continuation) = state else {
                return nil
            }

            return continuation
        }
    }

    private enum State {
        case pending
        case parked(CheckedContinuation<Void, any Error>)
        case finished
    }
}

private final class StreamReaderSpy<Element: Sendable>: Sendable {
    let values = AsyncRecord<Element>()

    private let task: Task<Void, Never>

    init(stream: AsyncStream<Element>) {
        task = Task { [values] in
            for await value in stream {
                values.append(value)
            }
        }
    }

    deinit {
        task.cancel()
    }
}
