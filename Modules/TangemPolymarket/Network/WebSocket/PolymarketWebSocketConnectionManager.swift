//
//  PolymarketWebSocketConnectionManager.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemLogger
import TangemWebSocket
import UIKit

actor PolymarketWebSocketConnectionManager {
    let messages: AsyncStream<WebSocketMessage>
    let statusChanges: AsyncStream<PolymarketWebSocketConnectionStatus>

    private let url: URL
    private let keepalive: Keepalive
    private let transport: any WebSocketTransport
    private let delayProvider: any PollDelayProvider
    private let notificationCenter: NotificationCenter
    private let messageContinuation: AsyncStream<WebSocketMessage>.Continuation
    private let statusContinuation: AsyncStream<PolymarketWebSocketConnectionStatus>.Continuation

    private var state: PolymarketWebSocketMachine.State = .idle
    private var connection: (any WebSocketConnection)?
    private var generation = 0
    private var retryTimerID = 0
    private var receivedMessageCount = 0
    private var receivedMessageCountAtLastPing: Int?

    private var openTask: Task<Void, Never>?
    private var readTask: Task<Void, Never>?
    private var retryTask: Task<Void, Never>?
    private var keepaliveTask: Task<Void, Never>?
    private var foregroundTask: Task<Void, Never>?

    var status: PolymarketWebSocketConnectionStatus {
        state.status
    }

    init(
        url: URL,
        keepalive: Keepalive,
        transport: any WebSocketTransport = URLSessionWebSocketTransport(),
        delayProvider: any PollDelayProvider = TaskSleepPollDelayProvider(),
        notificationCenter: NotificationCenter = .default
    ) {
        self.url = url
        self.keepalive = keepalive
        self.transport = transport
        self.delayProvider = delayProvider
        self.notificationCenter = notificationCenter
        (messages, messageContinuation) = AsyncStream.makeStream(of: WebSocketMessage.self)
        (statusChanges, statusContinuation) = AsyncStream.makeStream(of: PolymarketWebSocketConnectionStatus.self)
    }

    deinit {
        connection?.close(code: .goingAway, reason: nil)
        openTask?.cancel()
        readTask?.cancel()
        retryTask?.cancel()
        keepaliveTask?.cancel()
        foregroundTask?.cancel()
        messageContinuation.finish()
        statusContinuation.finish()
    }

    func connect() {
        startObservingForegroundIfNeeded()
        handle(.connectRequested)
    }

    func disconnect() {
        handle(.disconnectRequested)
    }

    func send(_ message: WebSocketMessage) async throws(SendError) {
        guard case .connected = state, let connection else {
            throw .notConnected
        }

        do throws(WebSocketTransportError) {
            try await connection.send(message)
        } catch {
            throw .transport(error)
        }
    }
}

// MARK: - State machine

private extension PolymarketWebSocketConnectionManager {
    func handle(_ event: PolymarketWebSocketMachine.Event) {
        let previousStatus = state.status
        let effects = PolymarketWebSocketMachine.transition(&state, event)

        effects.forEach(perform)

        let currentStatus = state.status
        guard currentStatus != previousStatus else {
            return
        }

        PolymarketLogger.info("\(host): \(previousStatus) → \(currentStatus)")
        statusContinuation.yield(currentStatus)
    }

    func perform(_ effect: PolymarketWebSocketMachine.Effect) {
        switch effect {
        case .openConnection:
            openConnection()
        case .closeConnection(let code):
            closeConnection(code: code)
        case .scheduleRetry(let delay):
            scheduleRetry(after: delay)
        case .cancelRetry:
            cancelRetry()
        case .startKeepalive:
            startKeepalive()
        case .stopKeepalive:
            stopKeepalive()
        }
    }

    var host: String {
        url.host() ?? "unknown host"
    }
}

// MARK: - Connection

private extension PolymarketWebSocketConnectionManager {
    func openConnection() {
        generation += 1
        let generation = generation

        openTask?.cancel()
        openTask = Task { [weak self, url, transport] in
            do {
                let connection = try await Task.run(withTimeout: Constants.connectTimeout) {
                    try await transport.connect(to: url, headers: [:])
                }
                await self?.opened(connection, generation: generation)
            } catch is TaskTimeoutError {
                await self?.openFailed(.handshakeTimeout, generation: generation)
            } catch let error as WebSocketTransportError {
                guard let disconnection = Self.disconnection(for: error) else {
                    return
                }

                await self?.openFailed(disconnection, generation: generation)
            } catch {
                return
            }
        }
    }

    func opened(_ connection: any WebSocketConnection, generation: Int) {
        guard generation == self.generation else {
            connection.close(code: .normalClosure, reason: nil)
            return
        }

        self.connection = connection
        startReading(connection, generation: generation)
        handle(.opened)
    }

    func openFailed(_ disconnection: PolymarketWebSocketDisconnection, generation: Int) {
        guard generation == self.generation else {
            return
        }

        log(disconnection)
        handle(.openFailed(disconnection))
    }

    func closeConnection(code: WebSocketCloseCode) {
        generation += 1
        connection?.close(code: code, reason: nil)
        connection = nil
        openTask?.cancel()
        readTask?.cancel()
    }

    func startReading(_ connection: any WebSocketConnection, generation: Int) {
        readTask?.cancel()
        readTask = Task { [weak self] in
            while !Task.isCancelled {
                do throws(WebSocketTransportError) {
                    let message = try await connection.receive()
                    await self?.received(message, generation: generation)
                } catch {
                    await self?.connectionFailed(with: error, generation: generation)
                    return
                }
            }
        }
    }

    func received(_ message: WebSocketMessage, generation: Int) {
        guard generation == self.generation else {
            return
        }

        receivedMessageCount += 1
        messageContinuation.yield(message)
    }

    func connectionFailed(with error: WebSocketTransportError, generation: Int) {
        guard generation == self.generation, let disconnection = Self.disconnection(for: error) else {
            return
        }

        log(disconnection)
        handle(.closed(disconnection))
    }

    static func disconnection(for error: WebSocketTransportError) -> PolymarketWebSocketDisconnection? {
        switch error {
        case .insecureURL:
            .insecureURL
        case .serverTrustRejected:
            .serverTrustRejected
        case .handshakeRejected(let statusCode):
            .handshakeRejected(statusCode: statusCode)
        case .closed(let code, let reason):
            .serverClosed(code: code, reason: reason)
        case .messageTooBig:
            .messageTooBig
        case .connectionFailed(let underlying):
            .connectionLost(underlying: underlying)
        case .cancelled:
            nil
        }
    }

    func log(_ disconnection: PolymarketWebSocketDisconnection) {
        switch disconnection {
        case .serverClosed(.policyViolation, _):
            PolymarketLogger.error("\(host): the server rejected our message", error: disconnection)
        case .serverClosed(let code, let reason):
            PolymarketLogger.info("\(host): closed by the server with code \(code.rawValue), reason: \(reason ?? "none")")
        case .connectionLost(let underlying):
            PolymarketLogger.error("\(host): connection lost", error: underlying)
        case .insecureURL, .serverTrustRejected, .handshakeRejected, .handshakeTimeout, .messageTooBig, .keepaliveTimeout:
            PolymarketLogger.warning("\(host): \(disconnection)")
        }
    }
}

// MARK: - Timers

private extension PolymarketWebSocketConnectionManager {
    func scheduleRetry(after delay: Duration) {
        retryTimerID += 1
        let timerID = retryTimerID
        PolymarketLogger.info("\(host): reconnecting in \(String(format: "%.3f", delay / .seconds(1))) seconds")

        retryTask?.cancel()
        retryTask = Task { [weak self, delayProvider] in
            guard await delayProvider.waitUnlessCancelled(delay) else {
                return
            }

            await self?.retryTimerFired(timerID: timerID)
        }
    }

    func retryTimerFired(timerID: Int) {
        guard timerID == retryTimerID else {
            return
        }

        handle(.retryTimerFired)
    }

    func cancelRetry() {
        retryTimerID += 1
        retryTask?.cancel()
    }
}

// MARK: - Keepalive

private extension PolymarketWebSocketConnectionManager {
    func startKeepalive() {
        keepaliveTask?.cancel()
        receivedMessageCountAtLastPing = nil

        let keepaliveCheck = makeKeepaliveCheck(generation: generation)
        keepaliveTask = Task { [delayProvider, interval = keepalive.interval] in
            while await delayProvider.waitUnlessCancelled(interval) {
                guard await keepaliveCheck() else {
                    return
                }
            }
        }
    }

    func stopKeepalive() {
        keepaliveTask?.cancel()
    }

    func makeKeepaliveCheck(generation: Int) -> @Sendable () async -> Bool {
        { [weak self, keepalive] in
            guard let connection = await self?.keepaliveConnection(generation: generation) else {
                return false
            }

            switch keepalive {
            case .protocolPing(_, let timeout):
                do {
                    try await Task.run(withTimeout: timeout) {
                        try await connection.ping()
                    }
                    return true
                } catch is TaskTimeoutError {
                    await self?.keepaliveTimedOut(generation: generation)
                    return false
                } catch let error as WebSocketTransportError {
                    await self?.connectionFailed(with: error, generation: generation)
                    return false
                } catch {
                    return false
                }

            case .textPing(let message, let interval):
                guard await self?.registerTextPing(generation: generation) == true else {
                    await self?.keepaliveTimedOut(generation: generation)
                    return false
                }

                do {
                    try await Task.run(withTimeout: interval) {
                        try await connection.send(message)
                    }
                    return true
                } catch is TaskTimeoutError {
                    await self?.keepaliveTimedOut(generation: generation)
                    return false
                } catch let error as WebSocketTransportError {
                    await self?.connectionFailed(with: error, generation: generation)
                    return false
                } catch {
                    return false
                }
            }
        }
    }

    func keepaliveConnection(generation: Int) -> (any WebSocketConnection)? {
        guard generation == self.generation else {
            return nil
        }

        return connection
    }

    func registerTextPing(generation: Int) -> Bool {
        guard generation == self.generation else {
            return false
        }

        let previousPingWasAnswered = receivedMessageCountAtLastPing.map { receivedMessageCount > $0 } ?? true
        receivedMessageCountAtLastPing = receivedMessageCount
        return previousPingWasAnswered
    }

    func keepaliveTimedOut(generation: Int) {
        guard generation == self.generation else {
            return
        }

        log(.keepaliveTimeout)
        handle(.closed(.keepaliveTimeout))
    }
}

// MARK: - App lifecycle

private extension PolymarketWebSocketConnectionManager {
    func startObservingForegroundIfNeeded() {
        guard foregroundTask == nil else {
            return
        }

        foregroundTask = Task { @MainActor [weak self, notificationCenter] in
            for await _ in notificationCenter.notifications(named: UIApplication.willEnterForegroundNotification) {
                await self?.appWillEnterForeground()
            }
        }
    }

    func appWillEnterForeground() {
        PolymarketLogger.info("\(host): app returned to the foreground")
        handle(.appWillEnterForeground)
    }
}

// MARK: - Auxiliary types

extension PolymarketWebSocketConnectionManager {
    enum Keepalive: Sendable {
        case textPing(WebSocketMessage, interval: Duration)
        case protocolPing(interval: Duration, timeout: Duration)

        var interval: Duration {
            switch self {
            case .textPing(_, let interval), .protocolPing(let interval, _):
                interval
            }
        }
    }

    enum SendError: Error {
        case notConnected
        case transport(WebSocketTransportError)
    }
}

// MARK: - Constants

private enum Constants {
    static let connectTimeout: Duration = .seconds(15)
}
