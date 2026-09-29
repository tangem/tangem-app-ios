//
//  TonConnectBridgeRequestFactory.swift
//  TangemModules
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Builds the two HTTP bridge requests (`spec/bridge.md`): `GET /events` and `POST /message`.
///
/// Kept separate from the transport so the exact URLs and headers are unit-testable.
public struct TonConnectBridgeRequestFactory: Sendable {
    /// Bridges must support at least 300 s; the wallet has no reason to ask for more.
    public static let defaultTTL = 300

    public let bridgeURL: URL

    public init(bridgeURL: URL) {
        self.bridgeURL = bridgeURL
    }

    /// `GET <bridge>/events?client_id=a,b,c[&last_event_id=…]` with `Accept: text/event-stream`.
    public func eventsRequest(clientIDs: [TonConnectClientID], lastEventID: String?) throws -> URLRequest {
        guard !clientIDs.isEmpty else {
            throw TonConnectError.internalFailure("no client ids to subscribe")
        }

        var items = [URLQueryItem(name: "client_id", value: clientIDs.map(\.hexString).joined(separator: ","))]
        if let lastEventID {
            items.append(URLQueryItem(name: "last_event_id", value: lastEventID))
        }
        // `heartbeat=message` makes keep-alives visible to non-browser clients.
        items.append(URLQueryItem(name: "heartbeat", value: "message"))

        var request = URLRequest(url: try url(path: "events", query: items))
        request.httpMethod = "GET"
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.timeoutInterval = 60 * 60
        return request
    }

    /// `POST <bridge>/message?client_id=&to=&ttl=[&topic=][&trace_id=]` with a base64 body.
    public func sendMessageRequest(
        from sender: TonConnectClientID,
        to recipient: TonConnectClientID,
        encryptedMessage: Data,
        ttl: Int = TonConnectBridgeRequestFactory.defaultTTL,
        topic: TonConnectMethod?,
        traceID: String?
    ) throws -> URLRequest {
        var items = [
            URLQueryItem(name: "client_id", value: sender.hexString),
            URLQueryItem(name: "to", value: recipient.hexString),
            URLQueryItem(name: "ttl", value: String(ttl)),
        ]
        if let topic {
            items.append(URLQueryItem(name: "topic", value: topic.rawValue))
        }
        if let traceID {
            items.append(URLQueryItem(name: "trace_id", value: traceID))
        }

        var request = URLRequest(url: try url(path: "message", query: items))
        request.httpMethod = "POST"
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data(encryptedMessage.base64EncodedString().utf8)
        request.timeoutInterval = 30
        return request
    }

    private func url(path: String, query: [URLQueryItem]) throws -> URL {
        // `https://host/bridge` and `https://host/bridge/` both become `https://host/bridge/events`.
        guard var components = URLComponents(url: bridgeURL.appendingPathComponent(path), resolvingAgainstBaseURL: false) else {
            throw TonConnectError.internalFailure("invalid bridge URL")
        }
        components.queryItems = query

        guard let url = components.url else {
            throw TonConnectError.internalFailure("invalid bridge URL")
        }
        return url
    }
}
