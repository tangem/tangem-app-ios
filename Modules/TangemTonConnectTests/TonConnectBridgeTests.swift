//
//  TonConnectBridgeTests.swift
//  TangemModules
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemTonConnect

@Suite(.tags(.tonConnect))
struct TonConnectSSEParserTests {
    @Test
    func parsesMultiLineEventsAndKeepsIdSticky() {
        var parser = TonConnectSSEParser()
        let lines = [
            ": comment",
            "id: 1700000000001",
            "event: message",
            "data: {\"from\":\"aa\",",
            "data: \"message\":\"bb\"}",
            "",
            "data: second",
            "",
            "retry: 5000",
            "id: 1700000000002",
            "data:third-no-space",
            "",
        ]

        let events = lines.compactMap { parser.feed(line: $0) }

        #expect(events == [
            TonConnectSSEEvent(id: "1700000000001", event: "message", data: "{\"from\":\"aa\",\n\"message\":\"bb\"}"),
            TonConnectSSEEvent(id: "1700000000001", event: nil, data: "second"),
            TonConnectSSEEvent(id: "1700000000002", event: nil, data: "third-no-space"),
        ])
    }

    @Test
    func ignoresBlankLinesWithoutDataAndStripsCR() {
        var parser = TonConnectSSEParser()

        #expect(parser.feed(line: "") == nil)
        #expect(parser.feed(line: "event: heartbeat\r") == nil)
        #expect(parser.feed(line: "") == nil, "event without data is dropped")
        #expect(parser.feed(line: "data: x\r") == nil)
        #expect(parser.feed(line: "\r") == TonConnectSSEEvent(id: nil, event: nil, data: "x"))
    }

    @Test
    func recognisesBothHeartbeatFormats() {
        #expect(TonConnectSSEEvent(id: nil, event: "heartbeat", data: "").isHeartbeat)
        #expect(TonConnectSSEEvent(id: nil, event: "message", data: "heartbeat").isHeartbeat)
        #expect(!TonConnectSSEEvent(id: nil, event: "message", data: "{}").isHeartbeat)
    }
}

@Suite(.tags(.tonConnect))
struct TonConnectBridgeMessageTests {
    @Test
    func decodesEnvelopeWithAndWithoutTraceID() throws {
        let from = String(repeating: "cd", count: 32)
        let payload = Data([1, 2, 3])

        let withTrace = try TonConnectBridgeMessage.decode(sseData: #"{"from":"\#(from)","message":"\#(payload.base64EncodedString())","trace_id":"t-1"}"#, eventID: "42")
        #expect(withTrace.from.hexString == from)
        #expect(withTrace.encryptedMessage == payload)
        #expect(withTrace.traceID == "t-1")
        #expect(withTrace.eventID == "42")

        let withoutTrace = try TonConnectBridgeMessage.decode(sseData: #"{"from":"\#(from)","message":"AQID"}"#, eventID: nil)
        #expect(withoutTrace.traceID == nil)
    }

    @Test
    func rejectsMalformedEnvelopes() {
        #expect(throws: TonConnectError.malformedEnvelope("BridgeMessage is not valid JSON")) {
            try TonConnectBridgeMessage.decode(sseData: "heartbeat", eventID: nil)
        }
        #expect(throws: TonConnectError.malformedEnvelope("BridgeMessage.message is not valid base64")) {
            try TonConnectBridgeMessage.decode(sseData: #"{"from":"\#(String(repeating: "cd", count: 32))","message":"***"}"#, eventID: nil)
        }
        #expect(throws: TonConnectError.invalidClientID) {
            try TonConnectBridgeMessage.decode(sseData: #"{"from":"nope","message":"AQID"}"#, eventID: nil)
        }
    }
}

@Suite(.tags(.tonConnect))
struct TonConnectBridgeRequestFactoryTests {
    private let wallet = try! TonConnectClientID(hexString: String(repeating: "aa", count: 32))
    private let dApp = try! TonConnectClientID(hexString: String(repeating: "bb", count: 32))

    @Test(arguments: ["https://connect.ton.org/bridge", "https://connect.ton.org/bridge/"])
    func buildsEventsRequest(bridge: String) throws {
        let factory = TonConnectBridgeRequestFactory(bridgeURL: URL(string: bridge)!)

        let request = try factory.eventsRequest(clientIDs: [wallet, dApp], lastEventID: "17")

        let components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
        #expect(components.scheme == "https")
        #expect(components.host == "connect.ton.org")
        #expect(components.path == "/bridge/events")
        let query = Dictionary(uniqueKeysWithValues: components.queryItems!.map { ($0.name, $0.value ?? "") })
        #expect(query["client_id"] == wallet.hexString + "," + dApp.hexString)
        #expect(query["last_event_id"] == "17")
        #expect(query["heartbeat"] == "message")
        #expect(request.httpMethod == "GET")
        #expect(request.value(forHTTPHeaderField: "Accept") == "text/event-stream")
    }

    @Test
    func eventsRequestOmitsLastEventIDWhenAbsentAndRejectsEmptySubscription() throws {
        let factory = TonConnectBridgeRequestFactory(bridgeURL: URL(string: "https://bridge.tonapi.io/bridge")!)

        let request = try factory.eventsRequest(clientIDs: [wallet], lastEventID: nil)
        #expect(!request.url!.absoluteString.contains("last_event_id"))

        #expect(throws: TonConnectError.self) {
            try factory.eventsRequest(clientIDs: [], lastEventID: nil)
        }
    }

    @Test
    func buildsSendMessageRequest() throws {
        let factory = TonConnectBridgeRequestFactory(bridgeURL: URL(string: "https://connect.ton.org/bridge")!)
        let ciphertext = Data([0xDE, 0xAD])

        let request = try factory.sendMessageRequest(from: wallet, to: dApp, encryptedMessage: ciphertext, topic: .sendTransaction, traceID: "trace")

        let components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
        #expect(components.path == "/bridge/message")
        let query = Dictionary(uniqueKeysWithValues: components.queryItems!.map { ($0.name, $0.value ?? "") })
        #expect(query == ["client_id": wallet.hexString, "to": dApp.hexString, "ttl": "300", "topic": "sendTransaction", "trace_id": "trace"])
        #expect(request.httpMethod == "POST")
        #expect(request.httpBody == Data(ciphertext.base64EncodedString().utf8))
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "text/plain")
    }

    @Test
    func sendMessageRequestOmitsOptionalParameters() throws {
        let factory = TonConnectBridgeRequestFactory(bridgeURL: URL(string: "https://connect.ton.org/bridge")!)

        let request = try factory.sendMessageRequest(from: wallet, to: dApp, encryptedMessage: Data([1]), ttl: 60, topic: nil, traceID: nil)

        let query = Dictionary(uniqueKeysWithValues: URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!.queryItems!.map { ($0.name, $0.value ?? "") })
        #expect(query == ["client_id": wallet.hexString, "to": dApp.hexString, "ttl": "60"])
    }
}
