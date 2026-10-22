//
//  WebSocketSessionDelegate.swift
//  TangemWebSocket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemNetworkUtils

final class WebSocketSessionDelegate: NSObject, Sendable {
    typealias OpeningResult = Result<Void, WebSocketTransportError>
    typealias OpeningContinuation = CheckedContinuation<OpeningResult, Never>

    private let state = OSAllocatedUnfairLock(initialState: State())

    func storeOpeningContinuation(_ continuation: OpeningContinuation) {
        let earlyResult: OpeningResult? = state.withLock { state in
            switch state.opening {
            case .pending, .waiting:
                state.opening = .waiting(continuation)
                return nil
            case .finished(let result):
                return result
            }
        }

        if let earlyResult {
            continuation.resume(returning: earlyResult)
        }
    }

    private func finishOpening(with result: OpeningResult) {
        let continuation: OpeningContinuation? = state.withLock { state in
            switch state.opening {
            case .pending:
                state.opening = .finished(result)
                return nil
            case .waiting(let continuation):
                state.opening = .finished(result)
                return continuation
            case .finished:
                return nil
            }
        }

        continuation?.resume(returning: result)
    }
}

// MARK: - URLSessionDelegate

extension WebSocketSessionDelegate: URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping @Sendable (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        let (disposition, credential) = TangemTrustEvaluatorUtil.evaluate(challenge: challenge)

        if disposition == .cancelAuthenticationChallenge {
            state.withLock { $0.isServerTrustRejected = true }
        }

        completionHandler(disposition, credential)
    }
}

// MARK: - URLSessionWebSocketDelegate

extension WebSocketSessionDelegate: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        finishOpening(with: .success(()))
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
        let isServerTrustRejected = state.withLock { $0.isServerTrustRejected }
        let openingError = Self.openingError(task: task, error: error, isServerTrustRejected: isServerTrustRejected)
        finishOpening(with: .failure(openingError))
    }
}

// MARK: - Private

private extension WebSocketSessionDelegate {
    struct State {
        var opening: Opening = .pending
        var isServerTrustRejected = false
    }

    enum Opening {
        case pending
        case waiting(OpeningContinuation)
        case finished(OpeningResult)
    }

    static func openingError(task: URLSessionTask, error: (any Error)?, isServerTrustRejected: Bool) -> WebSocketTransportError {
        if isServerTrustRejected {
            return .serverTrustRejected
        }

        if (error as? URLError)?.code == .cancelled {
            return .cancelled
        }

        if let response = task.response as? HTTPURLResponse, response.statusCode != 101 {
            return .handshakeRejected(statusCode: response.statusCode)
        }

        return .connectionFailed(underlying: error ?? URLError(.badServerResponse))
    }
}
