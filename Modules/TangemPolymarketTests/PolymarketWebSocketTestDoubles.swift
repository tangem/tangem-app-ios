//
//  PolymarketWebSocketTestDoubles.swift
//  TangemPolymarketTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemWebSocket

final class AsyncRecord<Element: Sendable>: Sendable {
    private let state = OSAllocatedUnfairLock(initialState: State())

    var elements: [Element] {
        state.withLock { $0.elements }
    }

    func append(_ element: Element) {
        let ready = state.withLock { state -> [CheckedContinuation<Element, any Error>] in
            state.elements.append(element)
            let index = state.elements.count - 1
            let ready = state.waiters.filter { $0.index == index }.map(\.continuation)
            state.waiters.removeAll { $0.index == index }
            return ready
        }

        ready.forEach { $0.resume(returning: element) }
    }

    @discardableResult
    func element(at index: Int) async throws -> Element {
        let id = UUID()

        _ = try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                let ready = state.withLock { state -> Result<Element, any Error>? in
                    guard !Task.isCancelled else {
                        return .failure(CancellationError())
                    }

                    guard index < state.elements.count else {
                        state.waiters.append(Waiter(id: id, index: index, continuation: continuation))
                        return nil
                    }

                    return .success(state.elements[index])
                }

                if let ready {
                    continuation.resume(with: ready)
                }
            }
        } onCancel: {
            state.withLock { state -> CheckedContinuation<Element, any Error>? in
                guard let position = state.waiters.firstIndex(where: { $0.id == id }) else {
                    return nil
                }

                return state.waiters.remove(at: position).continuation
            }?.resume(throwing: CancellationError())
        }

        return state.withLock { $0.elements[index] }
    }

    private struct State {
        var elements: [Element] = []
        var waiters: [Waiter] = []
    }

    private struct Waiter {
        let id: UUID
        let index: Int
        let continuation: CheckedContinuation<Element, any Error>
    }
}

final class WebSocketTransportSpy: WebSocketTransport {
    let connections = AsyncRecord<WebSocketConnectionSpy>()

    private let rejectedHandshakes: OSAllocatedUnfairLock<[Int]>

    init(rejectedHandshakes: [Int] = []) {
        self.rejectedHandshakes = OSAllocatedUnfairLock(initialState: rejectedHandshakes)
    }

    func connect(to url: URL, headers: [String: String]) async throws(WebSocketTransportError) -> any WebSocketConnection {
        let rejection = rejectedHandshakes.withLock { $0.isEmpty ? nil : $0.removeFirst() }

        if let rejection {
            throw .handshakeRejected(statusCode: rejection)
        }

        let connection = WebSocketConnectionSpy()
        connections.append(connection)
        return connection
    }
}

final class WebSocketConnectionSpy: WebSocketConnection {
    let sent = AsyncRecord<WebSocketMessage>()
    let closeCodes = AsyncRecord<WebSocketCloseCode>()

    private let state = OSAllocatedUnfairLock(initialState: State())

    func receive(_ text: String) {
        let waiter = state.withLock { state -> CheckedContinuation<WebSocketMessage, any Error>? in
            guard let waiter = state.waiter else {
                state.incoming.append(.text(text))
                return nil
            }

            state.waiter = nil
            return waiter
        }

        waiter?.resume(returning: .text(text))
    }

    func closeByServer(code: WebSocketCloseCode) {
        let waiter = state.withLock { state -> CheckedContinuation<WebSocketMessage, any Error>? in
            state.serverCloseCode = code
            defer { state.waiter = nil }
            return state.waiter
        }

        waiter?.resume(throwing: WebSocketTransportError.closed(code: code, reason: nil))
    }

    func failPings() {
        state.withLock { $0.pingsFail = true }
    }

    func send(_ message: WebSocketMessage) async throws(WebSocketTransportError) {
        sent.append(message)
    }

    func receive() async throws(WebSocketTransportError) -> WebSocketMessage {
        do {
            return try await withTaskCancellationHandler {
                try await withCheckedThrowingContinuation { continuation in
                    let message = state.withLock { state -> Result<WebSocketMessage, any Error>? in
                        guard !state.isClosedByClient, !Task.isCancelled else {
                            return .failure(WebSocketTransportError.cancelled)
                        }

                        if let code = state.serverCloseCode {
                            return .failure(WebSocketTransportError.closed(code: code, reason: nil))
                        }

                        guard state.incoming.isEmpty else {
                            return .success(state.incoming.removeFirst())
                        }

                        state.waiter = continuation
                        return nil
                    }

                    if let message {
                        continuation.resume(with: message)
                    }
                }
            } onCancel: {
                state.withLock { state in
                    defer { state.waiter = nil }
                    return state.waiter
                }?.resume(throwing: WebSocketTransportError.cancelled)
            }
        } catch let error as WebSocketTransportError {
            throw error
        } catch {
            throw .cancelled
        }
    }

    func ping() async throws(WebSocketTransportError) {
        if state.withLock({ $0.pingsFail }) {
            throw .connectionFailed(underlying: URLError(.networkConnectionLost))
        }
    }

    func close(code: WebSocketCloseCode, reason: String?) {
        closeCodes.append(code)

        state.withLock { state in
            state.isClosedByClient = true
            defer { state.waiter = nil }
            return state.waiter
        }?.resume(throwing: WebSocketTransportError.cancelled)
    }

    private struct State {
        var incoming: [WebSocketMessage] = []
        var waiter: CheckedContinuation<WebSocketMessage, any Error>?
        var serverCloseCode: WebSocketCloseCode?
        var pingsFail = false
        var isClosedByClient = false
    }
}
