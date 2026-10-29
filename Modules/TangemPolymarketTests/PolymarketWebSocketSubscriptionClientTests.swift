//
//  PolymarketWebSocketSubscriptionClientTests.swift
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

@Suite("Polymarket WebSocket subscription client", .timeLimit(.minutes(1)))
struct PolymarketWebSocketSubscriptionClientTests {
    // MARK: - Leaving readers

    @Test("A reader leaving while the socket is open keeps the values of the topics still read and forgets the rest")
    func leavingReaderForgetsOnlyItsOwnValues() async throws {
        let env = makeSUT()
        let (readerOfA, readerOfB, connection) = try await env.readTwoTopics()

        connection.receive("a=1;b=2")
        #expect(try await readerOfA.values.element(at: 0) == 1)
        #expect(try await readerOfB.values.element(at: 0) == 2)

        readerOfB.stop()
        try await env.delayProvider.parkedWaits(of: Constants.unsubscribeDelay, count: 1)
        env.delayProvider.release(Constants.unsubscribeDelay)
        #expect(try await connection.sent.element(at: 2) == .text("unsubscribe:b"))

        let newReaderOfA = await env.read(["a"])
        let newReaderOfB = await env.read(["b"])
        connection.receive("b=3")

        #expect(try await newReaderOfA.values.element(at: 0) == 1)
        #expect(try await newReaderOfB.values.element(at: 0) == 3)
        withExtendedLifetime(readerOfA) {}
    }

    @Test("A reader coming back before the topic is unsubscribed gets its latest value at once, without a new subscription")
    func quickReturnReplaysLatestValue() async throws {
        let env = makeSUT()
        let (reader, connection) = try await env.readOneTopic()

        connection.receive("a=1")
        #expect(try await reader.values.element(at: 0) == 1)

        reader.stop()
        try await env.delayProvider.parkedWaits(of: Constants.disconnectDelay, count: 2)

        let returningReader = await env.read(["a"])
        #expect(try await returningReader.values.element(at: 0) == 1)

        connection.receive("a=2")
        #expect(try await returningReader.values.element(at: 1) == 2)
        #expect(connection.sent.elements == [.text("subscribe-first:a")])
        #expect(env.transport.connections.elements.count == 1)
    }

    @Test("A reader coming back after the topic was unsubscribed gets no value cached before the unsubscription")
    func returnAfterUnsubscribeDoesNotReplayOldValues() async throws {
        let env = makeSUT()
        let (readerOfA, readerOfB, connection) = try await env.readTwoTopics()

        connection.receive("b=1")
        #expect(try await readerOfB.values.element(at: 0) == 1)

        readerOfB.stop()
        try await env.delayProvider.parkedWaits(of: Constants.unsubscribeDelay, count: 1)
        env.delayProvider.release(Constants.unsubscribeDelay)
        #expect(try await connection.sent.element(at: 2) == .text("unsubscribe:b"))

        let returningReader = await env.read(["b"])
        #expect(try await connection.sent.element(at: 3) == .text("subscribe:b"))
        connection.receive("b=2")

        #expect(try await returningReader.values.element(at: 0) == 2)
        withExtendedLifetime(readerOfA) {}
    }

    @Test("On a channel without subscriptions, like the sports one, a reader coming back within five seconds gets its latest value at once")
    func quickReturnReplaysLatestValueWithoutSubscriptions() async throws {
        let env = makeSUT(subscribes: false)
        let (reader, connection) = try await env.readWithoutSubscribing(["a"])

        connection.receive("a=1")
        #expect(try await reader.values.element(at: 0) == 1)

        reader.stop()
        try await env.delayProvider.parkedWaits(of: Constants.disconnectDelay, count: 1)

        let returningReader = await env.read(["a"])
        connection.receive("a=2")

        try #require(try await returningReader.values.element(at: 0) == 1)
        #expect(try await returningReader.values.element(at: 1) == 2)
        #expect(connection.sent.elements.isEmpty)
    }

    @Test("A reader coming back after the socket closed gets no value from the previous connection")
    func returnAfterDisconnectDoesNotReplayOldValues() async throws {
        let env = makeSUT()
        let (reader, connection) = try await env.readOneTopic()

        connection.receive("a=1")
        #expect(try await reader.values.element(at: 0) == 1)

        reader.stop()
        try await env.delayProvider.parkedWaits(of: Constants.disconnectDelay, count: 2)
        env.delayProvider.release(Constants.disconnectDelay)
        #expect(try await connection.closeCodes.element(at: 0) == .normalClosure)

        let returningReader = await env.read(["a"])
        let newConnection = try await env.transport.connections.element(at: 1)
        #expect(try await newConnection.sent.element(at: 0) == .text("subscribe-first:a"))
        newConnection.receive("a=2")

        #expect(try await returningReader.values.element(at: 0) == 2)
    }

    @Test("A topic nobody reads any more is unsubscribed five seconds later, the socket closes five seconds after the last reader")
    func unsubscribeAndDisconnectWaitFiveSeconds() async throws {
        let env = makeSUT()
        let (readerOfA, readerOfB, connection) = try await env.readTwoTopics()

        readerOfB.stop()
        try await env.delayProvider.parkedWaits(of: Constants.unsubscribeDelay, count: 1)
        env.delayProvider.release(Constants.unsubscribeDelay)
        #expect(try await connection.sent.element(at: 2) == .text("unsubscribe:b"))

        readerOfA.stop()
        try await env.delayProvider.parkedWaits(of: Constants.disconnectDelay, count: 2)
        env.delayProvider.release(Constants.disconnectDelay)

        #expect(try await connection.closeCodes.element(at: 0) == .normalClosure)
    }

    // MARK: - Silence

    @Test("Silence is counted from the last data, not from the connection")
    func silenceIsCountedFromTheLastData() async throws {
        let env = makeSUT()
        let (reader, connection) = try await env.readOneTopic()
        try await env.delayProvider.parkedWaits(of: Constants.silenceTimeout, count: 1)

        env.clock.advance(by: .seconds(30))
        connection.receive("a=1")
        #expect(try await reader.values.element(at: 0) == 1)

        env.clock.advance(by: .seconds(30))
        env.delayProvider.release(Constants.silenceTimeout)
        try await env.delayProvider.parkedWaits(of: .seconds(30), count: 1)

        #expect(connection.sent.elements.count == 1)

        env.clock.advance(by: .seconds(30))
        env.delayProvider.release(.seconds(30))

        #expect(try await connection.sent.element(at: 1) == .text("unsubscribe:a"))
        #expect(try await connection.sent.element(at: 2) == .text("subscribe:a"))
    }

    @Test("Data arriving after the silence probe keeps the socket open")
    func answeredProbeKeepsTheConnection() async throws {
        let env = makeSUT()
        let (reader, connection) = try await env.readOneTopic()

        try await env.probe(connection)
        env.clock.advance(by: .seconds(1))
        connection.receive("a=1")
        #expect(try await reader.values.element(at: 0) == 1)

        env.delayProvider.release(Constants.probeTimeout)
        try await env.delayProvider.parkedWaits(of: Constants.silenceTimeout, count: 1)

        #expect(env.transport.connections.elements.count == 1)
        #expect(connection.closeCodes.elements.isEmpty)
    }

    @Test("A reply to the silence probe that carries no values, as the server sends for a closed market, keeps the socket open")
    func valuelessProbeReplyKeepsTheConnection() async throws {
        let env = makeSUT()
        let (reader, connection) = try await env.readOneTopic()

        try await env.probe(connection)
        try await env.receiveAndWaitUntilHandled("[]", on: connection)
        env.delayProvider.release(Constants.probeTimeout)
        try await env.delayProvider.parkedWaits(of: Constants.silenceTimeout, count: 1)

        #expect(env.transport.connections.elements.count == 1)
        #expect(connection.closeCodes.elements.isEmpty)
        withExtendedLifetime(reader) {}
    }

    @Test("A keepalive reply does not answer the silence probe")
    func keepaliveReplyDoesNotAnswerTheProbe() async throws {
        let env = makeSUT()
        let (reader, connection) = try await env.readOneTopic()

        try await env.probe(connection)
        try await env.receiveAndWaitUntilHandled(ChannelStub.keepaliveReply, on: connection)
        env.delayProvider.release(Constants.probeTimeout)

        #expect(try await connection.closeCodes.element(at: 0) == .normalClosure)
        withExtendedLifetime(reader) {}
    }

    @Test("No data after the silence probe reconnects and subscribes to every topic read")
    func unansweredProbeReconnectsAndResubscribes() async throws {
        let env = makeSUT()
        let (readerOfA, readerOfB, connection) = try await env.readTwoTopics()

        try await env.probe(connection, sentBefore: 2)
        env.delayProvider.release(Constants.probeTimeout)

        #expect(try await connection.closeCodes.element(at: 0) == .normalClosure)

        let newConnection = try await env.transport.connections.element(at: 1)
        #expect(try await newConnection.sent.element(at: 0) == .text("subscribe-first:a,b"))
        withExtendedLifetime((readerOfA, readerOfB)) {}
    }

    @Test("A channel without a silence timeout, like the sports one, never probes or reconnects a quiet socket")
    func channelWithoutSilenceTimeoutNeverProbes() async throws {
        let env = makeSUT(silenceTimeout: nil)
        let (reader, connection) = try await env.readOneTopic()

        connection.receive("a=1")
        #expect(try await reader.values.element(at: 0) == 1)

        reader.stop()
        try await env.delayProvider.parkedWaits(of: Constants.disconnectDelay, count: 2)
        try await env.delayProvider.parkedWaits(of: Constants.keepaliveInterval, count: 1)

        #expect(!env.delayProvider.parkedSeconds.contains(Constants.silenceTimeout / .seconds(1)))
        #expect(connection.sent.elements == [.text("subscribe-first:a")])
        #expect(env.transport.connections.elements.count == 1)
    }

    @Test("Silence with no readers left only starts a new countdown")
    func silenceWithoutReadersOnlyRearms() async throws {
        let env = makeSUT()
        let (reader, connection) = try await env.readOneTopic()
        try await env.delayProvider.parkedWaits(of: Constants.silenceTimeout, count: 1)

        reader.stop()
        try await env.delayProvider.parkedWaits(of: Constants.disconnectDelay, count: 2)

        env.clock.advance(by: Constants.silenceTimeout)
        env.delayProvider.release(Constants.silenceTimeout)
        try await env.delayProvider.parkedWaits(of: Constants.silenceTimeout, count: 1)

        #expect(connection.sent.elements.count == 1)
        #expect(env.transport.connections.elements.count == 1)
    }
}

// MARK: - Helpers

private extension PolymarketWebSocketSubscriptionClientTests {
    func makeSUT(silenceTimeout: Duration? = Constants.silenceTimeout, subscribes: Bool = true) -> Environment {
        let transport = WebSocketTransportSpy()
        let delayProvider = DelayProviderSpy()
        let clock = ClockStub()
        let parsedMessages = AsyncRecord<WebSocketMessage>()

        let sut = PolymarketWebSocketSubscriptionClient(
            channel: ChannelStub(silenceTimeout: silenceTimeout, subscribes: subscribes, parsedMessages: parsedMessages),
            transport: transport,
            delayProvider: delayProvider,
            notificationCenter: NotificationCenter(),
            now: { clock.now }
        )

        return Environment(sut: sut, transport: transport, delayProvider: delayProvider, clock: clock, parsedMessages: parsedMessages)
    }

    struct Environment {
        let sut: PolymarketWebSocketSubscriptionClient<ChannelStub>
        let transport: WebSocketTransportSpy
        let delayProvider: DelayProviderSpy
        let clock: ClockStub
        let parsedMessages: AsyncRecord<WebSocketMessage>

        func receiveAndWaitUntilHandled(_ text: String, on connection: WebSocketConnectionSpy) async throws {
            let handled = parsedMessages.elements.count
            connection.receive(text)
            connection.receive(text)
            try await parsedMessages.element(at: handled + 1)
        }

        func read(_ topics: Set<String>) async -> ReaderSpy {
            ReaderSpy(stream: await sut.values(for: topics))
        }

        func readOneTopic() async throws -> (ReaderSpy, WebSocketConnectionSpy) {
            let reader = await read(["a"])
            let connection = try await transport.connections.element(at: 0)
            try await connection.sent.element(at: 0)

            return (reader, connection)
        }

        func readWithoutSubscribing(_ topics: Set<String>) async throws -> (ReaderSpy, WebSocketConnectionSpy) {
            let statuses = await sut.statusChanges()
            let reader = await read(topics)
            let connection = try await transport.connections.element(at: 0)

            for await status in statuses where status == .connected {
                break
            }

            return (reader, connection)
        }

        func readTwoTopics() async throws -> (ReaderSpy, ReaderSpy, WebSocketConnectionSpy) {
            let (readerOfA, connection) = try await readOneTopic()

            let readerOfB = await read(["b"])
            try await connection.sent.element(at: 1)

            return (readerOfA, readerOfB, connection)
        }

        func probe(_ connection: WebSocketConnectionSpy, sentBefore: Int = 1) async throws {
            try await connection.sent.element(at: sentBefore - 1)
            try await delayProvider.parkedWaits(of: Constants.silenceTimeout, count: 1)

            clock.advance(by: Constants.silenceTimeout)
            delayProvider.release(Constants.silenceTimeout)

            try await connection.sent.element(at: sentBefore + 1)
            try await delayProvider.parkedWaits(of: Constants.probeTimeout, count: 2)
        }
    }

    enum Constants {
        static let unsubscribeDelay: Duration = .seconds(5)
        static let disconnectDelay: Duration = .seconds(5)
        static let silenceTimeout: Duration = .seconds(60)
        static let probeTimeout: Duration = .seconds(10)
        static let keepaliveInterval: Duration = .seconds(10)
    }
}

// MARK: - Doubles

private struct ChannelStub: PolymarketWebSocketChannel, PolymarketWebSocketSubscribing {
    struct Update: Sendable {
        let topic: String
        let value: Int
    }

    static let keepaliveReply = "pong"

    let silenceTimeout: Duration?
    let subscribes: Bool
    let parsedMessages: AsyncRecord<WebSocketMessage>

    var url: URL {
        URL(string: "wss://channel.test")!
    }

    var keepalive: PolymarketWebSocketConnectionManager.Keepalive {
        .protocolPing(interval: PolymarketWebSocketSubscriptionClientTests.Constants.keepaliveInterval, timeout: .seconds(10))
    }

    var subscribing: (any PolymarketWebSocketSubscribing<String>)? {
        subscribes ? self : nil
    }

    func subscribeMessage(for topics: Set<String>, isFirstOnConnection: Bool) throws -> WebSocketMessage {
        .text("\(isFirstOnConnection ? "subscribe-first" : "subscribe"):\(topics.sorted().joined(separator: ","))")
    }

    func unsubscribeMessage(for topics: Set<String>) throws -> WebSocketMessage {
        .text("unsubscribe:\(topics.sorted().joined(separator: ","))")
    }

    func updates(from message: WebSocketMessage) throws -> [Update] {
        parsedMessages.append(message)

        guard case .text(let text) = message else {
            return []
        }

        return text.split(separator: ";").compactMap { pair in
            let parts = pair.split(separator: "=")

            guard parts.count == 2, let value = Int(parts[1]) else {
                return nil
            }

            return Update(topic: String(parts[0]), value: value)
        }
    }

    func isKeepaliveReply(_ message: WebSocketMessage) -> Bool {
        message == .text(Self.keepaliveReply)
    }

    func topic(of update: Update) -> String {
        update.topic
    }

    func value(applying update: Update, to previous: Int?) -> Int {
        update.value
    }
}

private final class DelayProviderSpy: PollDelayProvider, Sendable {
    private let state = OSAllocatedUnfairLock(initialState: State())

    func wait(for seconds: TimeInterval) async throws {
        let id = UUID()

        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                let (isCancelled, ready) = state.withLock { state -> (Bool, [CheckedContinuation<Void, any Error>]) in
                    guard !Task.isCancelled else {
                        return (true, [])
                    }

                    state.parked.append(ParkedWait(id: id, seconds: seconds, continuation: continuation))
                    return (false, state.takeSatisfiedObservers())
                }

                if isCancelled {
                    continuation.resume(throwing: CancellationError())
                }

                ready.forEach { $0.resume() }
            }
        } onCancel: {
            state.withLock { state -> CheckedContinuation<Void, any Error>? in
                guard let index = state.parked.firstIndex(where: { $0.id == id }) else {
                    return nil
                }

                return state.parked.remove(at: index).continuation
            }?.resume(throwing: CancellationError())
        }
    }

    func parkedWaits(of duration: Duration, count: Int) async throws {
        let seconds = duration / .seconds(1)
        let id = UUID()

        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                let ready = state.withLock { state -> Result<Void, any Error>? in
                    guard !Task.isCancelled else {
                        return .failure(CancellationError())
                    }

                    guard state.parkedCount(of: seconds) < count else {
                        return .success(())
                    }

                    state.observers.append(Observer(id: id, seconds: seconds, count: count, continuation: continuation))
                    return nil
                }

                if let ready {
                    continuation.resume(with: ready)
                }
            }
        } onCancel: {
            state.withLock { state -> CheckedContinuation<Void, any Error>? in
                guard let position = state.observers.firstIndex(where: { $0.id == id }) else {
                    return nil
                }

                return state.observers.remove(at: position).continuation
            }?.resume(throwing: CancellationError())
        }
    }

    var parkedSeconds: [TimeInterval] {
        state.withLock { $0.parked.map(\.seconds).sorted() }
    }

    func release(_ duration: Duration) {
        let seconds = duration / .seconds(1)

        let released = state.withLock { state in
            let released = state.parked.filter { $0.seconds == seconds }.map(\.continuation)
            state.parked.removeAll { $0.seconds == seconds }
            return released
        }

        released.forEach { $0.resume() }
    }

    private struct State {
        var parked: [ParkedWait] = []
        var observers: [Observer] = []

        func parkedCount(of seconds: TimeInterval) -> Int {
            parked.filter { $0.seconds == seconds }.count
        }

        mutating func takeSatisfiedObservers() -> [CheckedContinuation<Void, any Error>] {
            let parked = parked
            let isSatisfied: (Observer) -> Bool = { observer in
                parked.filter { $0.seconds == observer.seconds }.count >= observer.count
            }

            let satisfied = observers.filter(isSatisfied)
            observers.removeAll(where: isSatisfied)
            return satisfied.map(\.continuation)
        }
    }

    private struct ParkedWait {
        let id: UUID
        let seconds: TimeInterval
        let continuation: CheckedContinuation<Void, any Error>
    }

    private struct Observer {
        let id: UUID
        let seconds: TimeInterval
        let count: Int
        let continuation: CheckedContinuation<Void, any Error>
    }
}

private final class ClockStub: Sendable {
    private let origin = ContinuousClock.now
    private let offset = OSAllocatedUnfairLock(initialState: Duration.zero)

    var now: ContinuousClock.Instant {
        origin + offset.withLock { $0 }
    }

    func advance(by duration: Duration) {
        offset.withLock { $0 += duration }
    }
}

private final class ReaderSpy {
    let values = AsyncRecord<Int>()

    private let task: Task<Void, Never>

    init(stream: AsyncStream<Int>) {
        task = Task { [values] in
            for await value in stream {
                values.append(value)
            }
        }
    }

    func stop() {
        task.cancel()
    }
}
