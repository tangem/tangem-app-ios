//
//  TonConnectConnectRequest.swift
//  TangemModules
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// `ConnectRequest` — the JSON carried in the `r` parameter of a TON Connect link (`spec/connect.md`).
public struct TonConnectConnectRequest: Codable, Equatable, Sendable {
    public let manifestUrl: URL
    public let items: [TonConnectConnectItem]

    public init(manifestUrl: URL, items: [TonConnectConnectItem]) {
        self.manifestUrl = manifestUrl
        self.items = items
    }

    public var requestsProof: Bool {
        items.contains { item in
            if case .tonProof = item { return true }
            return false
        }
    }

    public var proofPayload: String? {
        for item in items {
            if case .tonProof(let payload) = item { return payload }
        }
        return nil
    }
}

/// A data item the dApp asks the wallet to share. Unknown item names are preserved so the wallet can
/// answer them with the per-item `METHOD_NOT_SUPPORTED` (400) error the spec requires.
public enum TonConnectConnectItem: Codable, Equatable, Sendable {
    case tonAddress(network: TonConnectNetworkID?)
    case tonProof(payload: String)
    case unsupported(name: String)

    public static let tonAddressName = "ton_addr"
    public static let tonProofName = "ton_proof"

    public var name: String {
        switch self {
        case .tonAddress: return Self.tonAddressName
        case .tonProof: return Self.tonProofName
        case .unsupported(let name): return name
        }
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case network
        case payload
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name = try container.decode(String.self, forKey: .name)

        switch name {
        case Self.tonAddressName:
            self = .tonAddress(network: try container.decodeIfPresent(TonConnectNetworkID.self, forKey: .network))
        case Self.tonProofName:
            self = .tonProof(payload: try container.decode(String.self, forKey: .payload))
        default:
            self = .unsupported(name: name)
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)

        switch self {
        case .tonAddress(let network):
            try container.encodeIfPresent(network, forKey: .network)
        case .tonProof(let payload):
            try container.encode(payload, forKey: .payload)
        case .unsupported:
            break
        }
    }
}
