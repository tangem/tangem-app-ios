//
//  TonConnectSignDataPayload.swift
//  TangemModules
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// `params[0]` of `signData` (`spec/rpc.md`). Echoed back verbatim inside the response.
public struct TonConnectSignDataPayload: Codable, Equatable, Sendable {
    public enum Content: Equatable, Sendable {
        case text(String)
        /// Raw bytes, transported as standard base64.
        case binary(Data)
        /// `cell` is a base64 single-root BoC; `schema` is its TL-B description.
        case cell(schema: String, cellBoc: String)

        public var type: TonConnectSignDataType {
            switch self {
            case .text: return .text
            case .binary: return .binary
            case .cell: return .cell
            }
        }
    }

    public let content: Content
    public let network: TonConnectNetworkID?
    public let from: String?

    public init(content: Content, network: TonConnectNetworkID?, from: String?) {
        self.content = content
        self.network = network
        self.from = from
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case text
        case bytes
        case schema
        case cell
        case network
        case from
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch TonConnectSignDataType(rawValue: type) {
        case .text:
            content = .text(try container.decode(String.self, forKey: .text))
        case .binary:
            let base64 = try container.decode(String.self, forKey: .bytes)
            guard let bytes = Data(base64Encoded: base64) else {
                throw DecodingError.dataCorruptedError(forKey: .bytes, in: container, debugDescription: "bytes is not valid base64")
            }
            content = .binary(bytes)
        case .cell:
            content = .cell(
                schema: try container.decode(String.self, forKey: .schema),
                cellBoc: try container.decode(String.self, forKey: .cell)
            )
        case nil:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "unknown signData type \(type)")
        }

        network = try container.decodeIfPresent(TonConnectNetworkID.self, forKey: .network)
        from = try container.decodeIfPresent(String.self, forKey: .from)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(content.type, forKey: .type)

        switch content {
        case .text(let text):
            try container.encode(text, forKey: .text)
        case .binary(let bytes):
            try container.encode(bytes.base64EncodedString(), forKey: .bytes)
        case .cell(let schema, let cellBoc):
            try container.encode(schema, forKey: .schema)
            try container.encode(cellBoc, forKey: .cell)
        }

        try container.encodeIfPresent(network, forKey: .network)
        try container.encodeIfPresent(from, forKey: .from)
    }

    public static func decode(from json: Data) throws -> TonConnectSignDataPayload {
        do {
            return try JSONDecoder().decode(TonConnectSignDataPayload.self, from: json)
        } catch {
            throw TonConnectError.badRequest("signData payload is malformed")
        }
    }
}
