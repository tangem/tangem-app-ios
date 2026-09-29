//
//  TonConnectBridgeClient.swift
//  TangemModules
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// HTTP bridge transport (`spec/bridge.md`) on top of `URLSession`.
///
/// The bridge is fully untrusted: it only ever sees `client_id`s and ciphertext. Encryption and
/// decryption happen in `TonConnectSessionCrypto`; this type moves bytes.
public final class TonConnectBridgeClient: Sendable {
    public enum TransportError: Error, Equatable {
        case httpStatus(Int)
        case notHTTPResponse
    }

    private let requestFactory: TonConnectBridgeRequestFactory
    private let session: URLSession

    public init(bridgeURL: URL, session: URLSession = .shared) {
        requestFactory = TonConnectBridgeRequestFactory(bridgeURL: bridgeURL)
        self.session = session
    }

    /// Posts an encrypted message for `recipient`. The bridge buffers it up to `ttl` seconds.
    public func send(
        _ encryptedMessage: Data,
        from sender: TonConnectClientID,
        to recipient: TonConnectClientID,
        topic: TonConnectMethod?,
        traceID: String?
    ) async throws {
        let request = try requestFactory.sendMessageRequest(
            from: sender,
            to: recipient,
            encryptedMessage: encryptedMessage,
            topic: topic,
            traceID: traceID
        )

        let (_, response) = try await session.data(for: request)
        try Self.validate(response)
    }

    /// Subscribes to the queues of `clientIDs` and yields every `BridgeMessage` until the connection
    /// drops or the task is cancelled. Heartbeats are filtered; malformed envelopes are skipped.
    ///
    /// Reconnection (with the last seen `eventID` as `last_event_id`) is the caller's responsibility so it
    /// can apply its own back-off and lifecycle rules.
    public func events(
        clientIDs: [TonConnectClientID],
        lastEventID: String?
    ) -> AsyncThrowingStream<TonConnectBridgeMessage, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let request = try requestFactory.eventsRequest(clientIDs: clientIDs, lastEventID: lastEventID)
                    let (bytes, response) = try await session.bytes(for: request)
                    try Self.validate(response)

                    var parser = TonConnectSSEParser()
                    for try await line in bytes.lines {
                        try Task.checkCancellation()

                        guard let event = parser.feed(line: line), !event.isHeartbeat else {
                            continue
                        }

                        if let message = try? TonConnectBridgeMessage.decode(sseData: event.data, eventID: event.id) {
                            continuation.yield(message)
                        }
                    }

                    // `bytes.lines` does not emit the trailing event when the stream ends without a blank line.
                    if let event = parser.feed(line: ""), !event.isHeartbeat,
                       let message = try? TonConnectBridgeMessage.decode(sseData: event.data, eventID: event.id) {
                        continuation.yield(message)
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    private static func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw TransportError.notHTTPResponse
        }
        guard (200 ..< 300).contains(http.statusCode) else {
            throw TransportError.httpStatus(http.statusCode)
        }
    }
}
