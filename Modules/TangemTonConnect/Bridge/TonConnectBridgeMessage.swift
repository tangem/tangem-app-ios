//
//  TonConnectBridgeMessage.swift
//  TangemModules
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// `BridgeMessage` envelope written by the bridge to the wallet's SSE channel (`spec/bridge.md`).
public struct TonConnectBridgeMessage: Equatable, Sendable {
    /// SSE `id:` of the event; pass it back as `last_event_id` on reconnect.
    public let eventID: String?
    /// Sender `client_id` (the dApp).
    public let from: TonConnectClientID
    /// `nonce ++ ciphertext`, already base64-decoded.
    public let encryptedMessage: Data
    public let traceID: String?

    public init(eventID: String?, from: TonConnectClientID, encryptedMessage: Data, traceID: String?) {
        self.eventID = eventID
        self.from = from
        self.encryptedMessage = encryptedMessage
        self.traceID = traceID
    }

    private struct DTO: Decodable {
        let from: String
        let message: String
        let traceId: String?

        private enum CodingKeys: String, CodingKey {
            case from
            case message
            case traceId = "trace_id"
        }
    }

    /// Decodes the `data:` field of an SSE event. Heartbeats are not `BridgeMessage`s and must be filtered before.
    public static func decode(sseData: String, eventID: String?) throws -> TonConnectBridgeMessage {
        let dto: DTO
        do {
            dto = try JSONDecoder().decode(DTO.self, from: Data(sseData.utf8))
        } catch {
            throw TonConnectError.malformedEnvelope("BridgeMessage is not valid JSON")
        }

        guard let encrypted = Data(base64Encoded: dto.message) else {
            throw TonConnectError.malformedEnvelope("BridgeMessage.message is not valid base64")
        }

        return TonConnectBridgeMessage(
            eventID: eventID,
            from: try TonConnectClientID(hexString: dto.from),
            encryptedMessage: encrypted,
            traceID: dto.traceId
        )
    }
}
