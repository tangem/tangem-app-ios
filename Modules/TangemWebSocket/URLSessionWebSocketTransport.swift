//
//  URLSessionWebSocketTransport.swift
//  TangemWebSocket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct URLSessionWebSocketTransport: WebSocketTransport {
    /// The largest single message, in bytes, that a connection buffers in memory before `receive()` fails.
    /// URLSession defaults to 1 MiB. 5 MiB is a middle ground for typical feeds; a feature whose server
    /// sends larger messages passes its own value.
    static let defaultMaximumMessageSize = 5 * 1024 * 1024

    private let maximumMessageSize: Int
    private let allowsInsecureConnections: Bool

    /// - Parameter allowsInsecureConnections: Lets `connect` open plain `ws://` URLs for debugging, provided
    ///   App Transport Security allows insecure connections to that host. Has no effect outside `INTERNAL` and `DEBUG`
    ///   builds: a production build accepts only `wss://`, even when this is `true`.
    init(
        maximumMessageSize: Int = Self.defaultMaximumMessageSize,
        allowsInsecureConnections: Bool = false
    ) {
        self.maximumMessageSize = maximumMessageSize
        self.allowsInsecureConnections = allowsInsecureConnections
    }

    func connect(to url: URL, headers: [String: String]) async throws(WebSocketTransportError) -> any WebSocketConnection {
        guard isAllowed(url) else {
            throw .insecureURL
        }

        let delegate = WebSocketSessionDelegate()
        let session = URLSession(configuration: .ephemeral, delegate: delegate, delegateQueue: nil)

        var request = URLRequest(url: url)
        for (name, value) in headers {
            request.setValue(value, forHTTPHeaderField: name)
        }

        let task = session.webSocketTask(with: request)
        task.maximumMessageSize = maximumMessageSize

        let result = await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                delegate.storeOpeningContinuation(continuation)
                task.resume()
            }
        } onCancel: {
            task.cancel()
        }

        switch result {
        case .success where Task.isCancelled:
            session.invalidateAndCancel()
            throw .cancelled
        case .success:
            return URLSessionWebSocketConnection(task: task, session: session)
        case .failure(let error):
            session.invalidateAndCancel()
            throw error
        }
    }
}

// MARK: - Private

private extension URLSessionWebSocketTransport {
    func isAllowed(_ url: URL) -> Bool {
        let scheme = url.scheme?.lowercased()

        if scheme == "wss" {
            return true
        }

        #if INTERNAL || DEBUG
        return scheme == "ws" && allowsInsecureConnections
        #else
        return false
        #endif
    }
}
