//
//  WebSocketConnection.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

actor WebSocketConnection {
    private let url: URL
    private let ping: Ping
    private let timeout: TimeInterval

    private var _sessionWebSocketTask: Task<URLSessionWebSocketTaskWrapper, any Error>?
    private var pingTask: Task<Void, Error>?
    private var timeoutTask: Task<Void, Error>?

    /// - Parameters:
    ///   - url: A `wss` URL
    ///   - ping: The value that will be sent after a certain interval in seconds
    ///   - timeout: The value in seconds through which the connection will be terminated, if there are no new `send` calls
    init(url: URL, ping: Ping, timeout: TimeInterval) {
        self.url = url
        self.ping = ping
        self.timeout = timeout
    }

    deinit {
        pingTask?.cancel()
        timeoutTask?.cancel()
        _sessionWebSocketTask?.cancel()
    }

    func send(_ message: URLSessionWebSocketTask.Message) async throws {
        let webSocketTask = try await setupWebSocketTask()
        BSDKLogger.info(self, "Send: \(message)")

        // Send a message
        try await webSocketTask.send(message: message)
        startPingTask()

        // Restart the disconnect timer
        startTimeoutTask()
    }

    func receive() async throws -> Data {
        guard let webSocket = try await _sessionWebSocketTask?.value else {
            throw WebSocketConnectionError.webSocketNotFound
        }

        // Get a message from the last response
        let response = try await webSocket.receive()
        BSDKLogger.info(self, "Receive: \(response)")

        let data = try mapToData(from: response)
        return data
    }
}

// MARK: - Private

private extension WebSocketConnection {
    func startPingTask() {
        pingTask?.cancel()
        // Sleep without holding `self` — a strong capture would keep the actor alive
        // between re-arms, so it could never deallocate while the loop is running
        pingTask = Task { [weak self, interval = ping.interval] in
            try await Task.sleep(nanoseconds: UInt64(interval) * NSEC_PER_SEC)

            try await self?.ping()
        }
    }

    func startTimeoutTask() {
        timeoutTask?.cancel()
        timeoutTask = Task { [weak self, timeout] in
            try await Task.sleep(nanoseconds: UInt64(timeout) * NSEC_PER_SEC)

            await self?.disconnect()
        }
    }

    func ping() async throws {
        guard let webSocket = try await _sessionWebSocketTask?.value else {
            throw WebSocketConnectionError.webSocketNotFound
        }

        switch ping {
        case .message(_, let message):
            BSDKLogger.info(self, "Send ping: \(message)")
            try await webSocket.send(message: message)

        case .plain:
            BSDKLogger.info(self, "Send plain ping")
            try await webSocket.sendPing()
        }

        startPingTask()
    }

    func setupWebSocketTask() async throws -> URLSessionWebSocketTaskWrapper {
        if let _sessionWebSocketTask {
            let socket = try await _sessionWebSocketTask.value
            BSDKLogger.info(self, "Return existed \(socket)")
            return socket
        }

        let connectingTask = Task {
            let socket = URLSessionWebSocketTaskWrapper(url: url)

            BSDKLogger.info(self, "\(socket) start connect")
            try await socket.connect()
            BSDKLogger.info(self, "\(socket) did open")

            return socket
        }

        _sessionWebSocketTask = connectingTask
        return try await connectingTask.value
    }

    func mapToData(from message: URLSessionWebSocketTask.Message) throws -> Data {
        switch message {
        case .data(let data):
            return data

        case .string(let string):
            guard let data = string.data(using: .utf8) else {
                throw WebSocketConnectionError.invalidResponse
            }

            return data

        @unknown default:
            fatalError()
        }
    }

    func disconnect() {
        pingTask?.cancel()
        timeoutTask?.cancel()
        _sessionWebSocketTask?.cancel()
        _sessionWebSocketTask = nil
    }
}

// MARK: - CustomStringConvertible

extension WebSocketConnection: CustomStringConvertible {
    nonisolated var description: String {
        objectDescription(self)
    }
}

// MARK: - Ping

extension WebSocketConnection {
    enum Ping {
        case plain(interval: TimeInterval = Constants.interval)
        case message(interval: TimeInterval = Constants.interval, message: URLSessionWebSocketTask.Message)

        var interval: TimeInterval {
            switch self {
            case .plain(let interval):
                return interval
            case .message(let interval, _):
                return interval
            }
        }
    }
}

// MARK: - Ping + Constants

extension WebSocketConnection.Ping {
    enum Constants {
        static let id: Int = -1
        static let interval: TimeInterval = 5
    }
}

// MARK: - Error

enum WebSocketConnectionError: Error {
    case webSocketNotFound
    case webSocketNotFoundTask
    case invalidResponse
}
