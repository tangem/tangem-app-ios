//
//  TonConnectConnectEvent.swift
//  TangemModules
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Wallet → dApp reply to a `ConnectRequest` (`spec/connect.md`).
public enum TonConnectConnectEvent: Encodable, Equatable, Sendable {
    case connect(id: Int, items: [TonConnectConnectItemReply], device: TonConnectDeviceInfo)
    case connectError(id: Int, code: TonConnectErrorCode, message: String)

    private enum CodingKeys: String, CodingKey {
        case event
        case id
        case payload
    }

    private enum SuccessPayloadKeys: String, CodingKey {
        case items
        case device
    }

    private enum ErrorPayloadKeys: String, CodingKey {
        case code
        case message
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .connect(let id, let items, let device):
            try container.encode("connect", forKey: .event)
            try container.encode(id, forKey: .id)
            var payload = container.nestedContainer(keyedBy: SuccessPayloadKeys.self, forKey: .payload)
            try payload.encode(items, forKey: .items)
            try payload.encode(device, forKey: .device)
        case .connectError(let id, let code, let message):
            try container.encode("connect_error", forKey: .event)
            try container.encode(id, forKey: .id)
            var payload = container.nestedContainer(keyedBy: ErrorPayloadKeys.self, forKey: .payload)
            try payload.encode(code.rawValue, forKey: .code)
            try payload.encode(message, forKey: .message)
        }
    }
}

/// One entry of `ConnectEventSuccess.payload.items`.
public enum TonConnectConnectItemReply: Encodable, Equatable, Sendable {
    case tonAddress(TonConnectAddressItemReply)
    case tonProof(TonConnectProof)
    /// Per-item error, e.g. code 400 for an item the wallet does not support.
    case error(name: String, code: TonConnectErrorCode, message: String?)

    private enum CodingKeys: String, CodingKey {
        case name
        case address
        case network
        case publicKey
        case walletStateInit
        case proof
        case error
    }

    private enum ErrorKeys: String, CodingKey {
        case code
        case message
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .tonAddress(let reply):
            try container.encode(TonConnectConnectItem.tonAddressName, forKey: .name)
            try container.encode(reply.address, forKey: .address)
            try container.encode(reply.network, forKey: .network)
            try container.encode(reply.publicKey, forKey: .publicKey)
            try container.encode(reply.walletStateInit, forKey: .walletStateInit)
        case .tonProof(let proof):
            try container.encode(TonConnectConnectItem.tonProofName, forKey: .name)
            try container.encode(proof, forKey: .proof)
        case .error(let name, let code, let message):
            try container.encode(name, forKey: .name)
            var error = container.nestedContainer(keyedBy: ErrorKeys.self, forKey: .error)
            try error.encode(code.rawValue, forKey: .code)
            try error.encodeIfPresent(message, forKey: .message)
        }
    }
}

/// `TonAddressItemReply` fields.
public struct TonConnectAddressItemReply: Equatable, Sendable {
    /// Raw form `0:<hex>`.
    public let address: String
    public let network: TonConnectNetworkID
    /// Hex without `0x`.
    public let publicKey: String
    /// Standard (not url-safe) base64 BoC of the wallet contract's `StateInit`.
    public let walletStateInit: String

    public init(address: String, network: TonConnectNetworkID, publicKey: String, walletStateInit: String) {
        self.address = address
        self.network = network
        self.publicKey = publicKey
        self.walletStateInit = walletStateInit
    }
}

/// `TonProofItemReplySuccess.proof`.
public struct TonConnectProof: Encodable, Equatable, Sendable {
    public struct Domain: Encodable, Equatable, Sendable {
        public let lengthBytes: Int
        public let value: String

        public init(value: String) {
            self.value = value
            lengthBytes = value.utf8.count
        }
    }

    /// Unix seconds, serialised as a string per spec.
    public let timestamp: String
    public let domain: Domain
    /// Base64 (standard alphabet) Ed25519 signature.
    public let signature: String
    public let payload: String

    public init(timestamp: UInt64, domain: String, signature: Data, payload: String) {
        self.timestamp = String(timestamp)
        self.domain = Domain(value: domain)
        self.signature = signature.base64EncodedString()
        self.payload = payload
    }
}
