//
//  PolymarketWebSocketSubscriptionClient.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemLogger
import TangemWebSocket

actor PolymarketWebSocketSubscriptionClient<Channel: PolymarketWebSocketChannel> {
    typealias Topic = Channel.Topic
    typealias Update = Channel.Update
    typealias Value = Channel.Value

    private let channel: Channel
    private let manager: PolymarketWebSocketConnectionManager
    private let delayProvider: any PollDelayProvider
    private let now: @Sendable () -> ContinuousClock.Instant

    private var readers: [UUID: Reader] = [:]
    private var statusObservers: [UUID: AsyncStream<PolymarketWebSocketConnectionStatus>.Continuation] = [:]
    private var connectionStatus: PolymarketWebSocketConnectionStatus = .idle
    private var activeConnection: ActiveConnection?

    private var statusTask: Task<Void, Never>?
    private var messagesTask: Task<Void, Never>?
    private var unsubscribeTask: Task<Void, Never>?
    private var disconnectTask: Task<Void, Never>?
    private var silenceTask: Task<Void, Never>?
    private var lastDataAt: ContinuousClock.Instant?

    init(
        channel: Channel,
        transport: any WebSocketTransport = URLSessionWebSocketTransport(),
        delayProvider: any PollDelayProvider = TaskSleepPollDelayProvider(),
        notificationCenter: NotificationCenter = .default,
        now: @escaping @Sendable () -> ContinuousClock.Instant = { ContinuousClock.now }
    ) {
        self.channel = channel
        self.delayProvider = delayProvider
        self.now = now
        manager = PolymarketWebSocketConnectionManager(
            url: channel.url,
            keepalive: channel.keepalive,
            transport: transport,
            delayProvider: delayProvider,
            notificationCenter: notificationCenter
        )
    }

    deinit {
        statusTask?.cancel()
        messagesTask?.cancel()
        unsubscribeTask?.cancel()
        disconnectTask?.cancel()
        silenceTask?.cancel()
        readers.values.forEach { $0.continuation.finish() }
        statusObservers.values.forEach { $0.finish() }
    }

    func values(for topics: Set<Topic>) async -> AsyncStream<Value> {
        let (stream, continuation) = AsyncStream.makeStream(of: Value.self)

        guard !topics.isEmpty else {
            continuation.finish()
            return stream
        }

        let id = UUID()

        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeReader(id: id) }
        }

        readers[id] = Reader(topics: topics, continuation: continuation)
        cancelDisconnect()

        if let latestValues = activeConnection?.latestValues {
            topics.compactMap { latestValues[$0] }.forEach { continuation.yield($0) }
        }

        syncSubscriptions()
        startObservingStatusIfNeeded()
        startReadingMessagesIfNeeded()
        await connectIfNeeded()

        return stream
    }

    func statusChanges() -> AsyncStream<PolymarketWebSocketConnectionStatus> {
        let (stream, continuation) = AsyncStream.makeStream(
            of: PolymarketWebSocketConnectionStatus.self,
            bufferingPolicy: .bufferingNewest(1)
        )
        let id = UUID()

        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeStatusObserver(id: id) }
        }

        statusObservers[id] = continuation
        continuation.yield(connectionStatus)

        return stream
    }
}

// MARK: - Readers

private extension PolymarketWebSocketSubscriptionClient {
    var wantedTopics: Set<Topic> {
        readers.values.reduce(into: []) { $0.formUnion($1.topics) }
    }

    var followedTopics: Set<Topic> {
        wantedTopics.union(activeConnection?.subscribedTopics ?? [])
    }

    func removeReader(id: UUID) {
        guard readers.removeValue(forKey: id) != nil else {
            return
        }

        forgetUnfollowedValues()
        scheduleUnsubscribeIfNeeded()

        if readers.isEmpty {
            activeConnection?.latestValues = [:]
            scheduleDisconnect()
        }
    }

    func removeStatusObserver(id: UUID) {
        statusObservers[id] = nil
    }
}

// MARK: - Connection

private extension PolymarketWebSocketSubscriptionClient {
    func startObservingStatusIfNeeded() {
        guard statusTask == nil else {
            return
        }

        statusTask = Task { [weak self, statusChanges = manager.statusChanges] in
            for await status in statusChanges {
                await self?.connectionStatusChanged(status)
            }
        }
    }

    func connectionStatusChanged(_ status: PolymarketWebSocketConnectionStatus) async {
        connectionStatus = status
        statusObservers.values.forEach { $0.yield(status) }

        switch status {
        case .connected where wantedTopics.isEmpty:
            PolymarketLogger.info("Subscription client: connected with nothing to subscribe to, disconnecting")
            await manager.disconnect()
            await connectIfNeeded()

        case .connected:
            activeConnection = ActiveConnection(outgoingQueue: OutgoingQueue(manager: manager))
            syncSubscriptions()
            lastDataAt = now()
            scheduleSilenceCheck(after: channel.silenceTimeout)

        case .idle, .connecting, .waitingToReconnect, .stopped:
            activeConnection = nil
            cancelSilenceCheck()
        }
    }

    func connectIfNeeded() async {
        guard !wantedTopics.isEmpty else {
            return
        }

        switch await manager.status {
        case .idle, .stopped:
            await manager.connect()
        case .connecting, .connected, .waitingToReconnect:
            break
        }
    }
}

// MARK: - Subscriptions

private extension PolymarketWebSocketSubscriptionClient {
    func syncSubscriptions() {
        guard let connection = activeConnection, let subscribing = channel.subscribing else {
            return
        }

        let newTopics = wantedTopics.subtracting(connection.subscribedTopics)

        guard !newTopics.isEmpty else {
            return
        }

        let message: WebSocketMessage

        do {
            message = try subscribing.subscribeMessage(for: newTopics, isFirstOnConnection: !connection.hasSentFirstSubscription)
        } catch {
            PolymarketLogger.error("Subscription client: failed to encode a subscription", error: error)
            return
        }

        connection.outgoingQueue.send(message)
        activeConnection?.subscribedTopics.formUnion(newTopics)
        activeConnection?.hasSentFirstSubscription = true
    }
}

// MARK: - Incoming messages

private extension PolymarketWebSocketSubscriptionClient {
    func startReadingMessagesIfNeeded() {
        guard messagesTask == nil else {
            return
        }

        messagesTask = Task { [weak self, messages = manager.messages, channel] in
            for await message in messages {
                let updates: [Update]

                do {
                    updates = try channel.updates(from: message)
                } catch {
                    PolymarketLogger.error("Subscription client: failed to decode a message", error: error)
                    continue
                }

                guard !updates.isEmpty else {
                    continue
                }

                await self?.deliver(updates)
            }
        }
    }

    func deliver(_ updates: [Update]) {
        let followed = followedTopics

        for update in updates {
            let topic = channel.topic(of: update)

            guard followed.contains(topic) else {
                continue
            }

            lastDataAt = now()

            let value = channel.value(applying: update, to: activeConnection?.latestValues[topic])
            activeConnection?.latestValues[topic] = value

            for reader in readers.values where reader.topics.contains(topic) {
                reader.continuation.yield(value)
            }
        }
    }
}

// MARK: - Silence

private extension PolymarketWebSocketSubscriptionClient {
    func scheduleSilenceCheck(after delay: Duration) {
        silenceTask?.cancel()

        silenceTask = Task { [weak self, delayProvider] in
            guard await delayProvider.waitUnlessCancelled(delay) else {
                return
            }

            await self?.silenceCheckFired()
        }
    }

    func cancelSilenceCheck() {
        silenceTask?.cancel()
        silenceTask = nil
        lastDataAt = nil
    }

    func silenceCheckFired() async {
        silenceTask = nil

        guard activeConnection != nil, let lastDataAt else {
            return
        }

        let silence = now() - lastDataAt

        guard silence >= channel.silenceTimeout else {
            scheduleSilenceCheck(after: channel.silenceTimeout - silence)
            return
        }

        guard !readers.isEmpty else {
            self.lastDataAt = now()
            scheduleSilenceCheck(after: channel.silenceTimeout)
            return
        }

        PolymarketLogger.info("Subscription client: no data for \(silence), probing the subscriptions")
        await probeSubscriptions()
    }

    func probeSubscriptions() async {
        guard let connection = activeConnection, let subscribing = channel.subscribing, !connection.subscribedTopics.isEmpty else {
            await reconnectAfterSilence()
            return
        }

        let topics = connection.subscribedTopics

        do {
            connection.outgoingQueue.send(try subscribing.unsubscribeMessage(for: topics))
            connection.outgoingQueue.send(try subscribing.subscribeMessage(for: topics, isFirstOnConnection: false))
        } catch {
            PolymarketLogger.error("Subscription client: failed to encode a subscription probe", error: error)
            await reconnectAfterSilence()
            return
        }

        let probeSentAt = now()

        silenceTask = Task { [weak self, delayProvider, timeout = channel.keepalive.interval] in
            guard await delayProvider.waitUnlessCancelled(timeout) else {
                return
            }

            await self?.probeTimedOut(sentAt: probeSentAt)
        }
    }

    func probeTimedOut(sentAt probeSentAt: ContinuousClock.Instant) async {
        silenceTask = nil

        guard activeConnection != nil, let lastDataAt else {
            return
        }

        guard lastDataAt < probeSentAt else {
            scheduleSilenceCheck(after: channel.silenceTimeout - (now() - lastDataAt))
            return
        }

        await reconnectAfterSilence()
    }

    func reconnectAfterSilence() async {
        PolymarketLogger.info("Subscription client: no answer to the subscription probe, reconnecting")
        await manager.disconnect()
        await connectIfNeeded()
    }
}

// MARK: - Timers

private extension PolymarketWebSocketSubscriptionClient {
    var unwantedTopics: Set<Topic> {
        activeConnection?.subscribedTopics.subtracting(wantedTopics) ?? []
    }

    func scheduleUnsubscribeIfNeeded() {
        guard unsubscribeTask == nil, !unwantedTopics.isEmpty else {
            return
        }

        unsubscribeTask = Task { [weak self, delayProvider] in
            guard await delayProvider.waitUnlessCancelled(Constants.unsubscribeDelay) else {
                return
            }

            await self?.unsubscribeTimerFired()
        }
    }

    func unsubscribeTimerFired() {
        unsubscribeTask = nil

        let topics = unwantedTopics

        guard let connection = activeConnection, let subscribing = channel.subscribing, !topics.isEmpty else {
            return
        }

        let message: WebSocketMessage

        do {
            message = try subscribing.unsubscribeMessage(for: topics)
        } catch {
            PolymarketLogger.error("Subscription client: failed to encode an unsubscription", error: error)
            return
        }

        connection.outgoingQueue.send(message)
        activeConnection?.subscribedTopics.subtract(topics)
        forgetUnfollowedValues()
    }

    func forgetUnfollowedValues() {
        guard let latestValues = activeConnection?.latestValues else {
            return
        }

        let followed = followedTopics
        activeConnection?.latestValues = latestValues.filter { followed.contains($0.key) }
    }

    func scheduleDisconnect() {
        guard disconnectTask == nil else {
            return
        }

        let delay = Constants.disconnectDelay

        disconnectTask = Task { [weak self, delayProvider] in
            guard await delayProvider.waitUnlessCancelled(delay) else {
                return
            }

            await self?.disconnectTimerFired()
        }
    }

    func cancelDisconnect() {
        disconnectTask?.cancel()
        disconnectTask = nil
    }

    func disconnectTimerFired() async {
        disconnectTask = nil

        guard readers.isEmpty else {
            return
        }

        PolymarketLogger.info("Subscription client: no readers left, disconnecting")
        await manager.disconnect()
        await connectIfNeeded()
    }
}

// MARK: - Auxiliary types

private extension PolymarketWebSocketSubscriptionClient {
    struct Reader {
        let topics: Set<Topic>
        let continuation: AsyncStream<Value>.Continuation
    }

    final class OutgoingQueue {
        private let continuation: AsyncStream<WebSocketMessage>.Continuation
        private let writerTask: Task<Void, Never>

        init(manager: PolymarketWebSocketConnectionManager) {
            let (messages, continuation) = AsyncStream.makeStream(of: WebSocketMessage.self)
            self.continuation = continuation

            writerTask = Task {
                for await message in messages {
                    guard !Task.isCancelled else {
                        return
                    }

                    do {
                        try await manager.send(message)
                    } catch {
                        PolymarketLogger.error("Subscription client: failed to send a message", error: error)
                    }
                }
            }
        }

        deinit {
            writerTask.cancel()
            continuation.finish()
        }

        func send(_ message: WebSocketMessage) {
            continuation.yield(message)
        }
    }

    struct ActiveConnection {
        let outgoingQueue: OutgoingQueue
        var subscribedTopics: Set<Topic> = []
        var hasSentFirstSubscription = false
        var latestValues: [Topic: Value] = [:]
    }
}

// MARK: - Constants

private enum Constants {
    static let unsubscribeDelay: Duration = .seconds(5)
    static let disconnectDelay: Duration = .seconds(5)
}
