//
//  URLSessionWebSocketConnection.swift
//  TangemWebSocket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

final class URLSessionWebSocketConnection: WebSocketConnection {
    private let task: URLSessionWebSocketTask
    private let session: URLSession
    private let isClosedByClient = OSAllocatedUnfairLock(initialState: false)

    init(task: URLSessionWebSocketTask, session: URLSession) {
        self.task = task
        self.session = session
    }

    deinit {
        task.cancel(with: .goingAway, reason: nil)
        session.invalidateAndCancel()
    }

    func send(_ message: WebSocketMessage) async throws(WebSocketTransportError) {
        let taskMessage: URLSessionWebSocketTask.Message = switch message {
        case .text(let text): .string(text)
        case .binary(let data): .data(data)
        }

        do {
            try await task.send(taskMessage)
        } catch {
            throw transportError(for: error)
        }
    }

    func receive() async throws(WebSocketTransportError) -> WebSocketMessage {
        while true {
            let message: URLSessionWebSocketTask.Message

            do {
                message = try await withTaskCancellationHandler {
                    try await task.receive()
                } onCancel: {
                    self.closeOnCancellation()
                }
            } catch {
                throw transportError(for: error)
            }

            switch message {
            case .string(let text):
                return .text(text)
            case .data(let data):
                return .binary(data)
            @unknown default:
                // `URLSessionWebSocketTask.Message` has only `.string` and `.data` today:
                // https://developer.apple.com/documentation/foundation/urlsessionwebsockettask/message
                // A kind added in a future OS is skipped, and the next message is read.
                continue
            }
        }
    }

    func ping() async throws(WebSocketTransportError) {
        let result: Result<Void, any Error> = await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                let isResumed = OSAllocatedUnfairLock(initialState: false)

                task.sendPing { error in
                    let isFirstCompletion = isResumed.withLock { isResumed in
                        let isFirst = !isResumed
                        isResumed = true
                        return isFirst
                    }

                    guard isFirstCompletion else {
                        return
                    }

                    continuation.resume(returning: error.map { .failure($0) } ?? .success(()))
                }
            }
        } onCancel: {
            self.closeOnCancellation()
        }

        if case .failure(let error) = result {
            throw transportError(for: error)
        }
    }

    func close(code: WebSocketCloseCode, reason: String?) {
        isClosedByClient.withLock { $0 = true }

        if code.isSendable, let closeCode = URLSessionWebSocketTask.CloseCode(rawValue: Int(code.rawValue)) {
            task.cancel(with: closeCode, reason: reason.flatMap(Self.closeReasonData))
        } else {
            task.cancel()
        }

        session.invalidateAndCancel()
    }
}

// MARK: - Private

private extension URLSessionWebSocketConnection {
    func closeOnCancellation() {
        isClosedByClient.withLock { $0 = true }
        task.cancel()
        session.invalidateAndCancel()
    }

    func transportError(for error: any Error) -> WebSocketTransportError {
        if isClosedByClient.withLock({ $0 }) || Task.isCancelled {
            return .cancelled
        }

        if task.closeCode != .invalid, let rawCode = UInt16(exactly: task.closeCode.rawValue) {
            let reason = task.closeReason.flatMap { String(data: $0, encoding: .utf8) }?.nilIfEmpty
            return .closed(code: WebSocketCloseCode(rawValue: rawCode), reason: reason)
        }

        if (error as? POSIXError)?.code == .EMSGSIZE {
            return .messageTooBig
        }

        return .connectionFailed(underlying: error)
    }
}

// MARK: - Close reason

extension URLSessionWebSocketConnection {
    static func closeReasonData(_ reason: String) -> Data? {
        var data = Data()

        for character in reason {
            let bytes = Data(String(character).utf8)

            guard data.count + bytes.count <= Constants.maximumCloseReasonByteCount else {
                break
            }

            data.append(bytes)
        }

        return data.count == Constants.unsendableCloseReasonByteCount ? nil : data
    }
}

// MARK: - Constants

private extension URLSessionWebSocketConnection {
    enum Constants {
        /// A close frame carries at most 125 bytes, two of which hold the code.
        /// See "Control Frames" in RFC 6455: https://datatracker.ietf.org/doc/html/rfc6455
        /// URLSession silently skips the whole close frame when the reason is longer, so the reason is truncated.
        static let maximumCloseReasonByteCount = 123

        /// URLSession silently skips the whole close frame when the reason is exactly one byte long,
        /// so such a reason is dropped and the frame goes out with the code only.
        static let unsendableCloseReasonByteCount = 1
    }
}
