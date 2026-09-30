//
//  TonConnectWalletResponse.swift
//  TangemModules
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// `WalletResponse` — the wallet's reply to an `AppRequest` (`spec/rpc.md`). `id` mirrors the request id.
public enum TonConnectWalletResponse: Encodable, Sendable {
    case success(id: String, result: TonConnectResponseResult)
    case error(id: String, code: TonConnectErrorCode, message: String)

    private enum CodingKeys: String, CodingKey {
        case id
        case result
        case error
    }

    private enum ErrorKeys: String, CodingKey {
        case code
        case message
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .success(let id, let result):
            try container.encode(id, forKey: .id)
            try container.encode(result, forKey: .result)
        case .error(let id, let code, let message):
            try container.encode(id, forKey: .id)
            var error = container.nestedContainer(keyedBy: ErrorKeys.self, forKey: .error)
            try error.encode(code.rawValue, forKey: .code)
            try error.encode(message, forKey: .message)
        }
    }

    /// Builds the error reply for a failed request.
    public static func failure(id: String, error: TonConnectError) -> TonConnectWalletResponse {
        .error(id: id, code: error.protocolCode, message: error.protocolMessage)
    }
}

/// Method-specific `result` shapes.
public enum TonConnectResponseResult: Encodable, Sendable {
    /// `sendTransaction`: base64 BoC of the broadcast external message.
    case sendTransaction(externalMessageBoc: String)
    /// `signMessage`: base64 BoC of the signed message that the dApp will relay.
    case signMessage(internalBoc: String)
    /// `signData`: signature plus the fields the dApp needs to verify it.
    case signData(TonConnectSignDataResult)
    /// `disconnect`: empty object.
    case disconnect

    private enum SignMessageKeys: String, CodingKey {
        case internalBoc
    }

    private struct Empty: Encodable {}

    public func encode(to encoder: any Encoder) throws {
        switch self {
        case .sendTransaction(let boc):
            var container = encoder.singleValueContainer()
            try container.encode(boc)
        case .signMessage(let boc):
            var container = encoder.container(keyedBy: SignMessageKeys.self)
            try container.encode(boc, forKey: .internalBoc)
        case .signData(let result):
            try result.encode(to: encoder)
        case .disconnect:
            try Empty().encode(to: encoder)
        }
    }
}

/// `SignDataResponseSuccess.result`.
public struct TonConnectSignDataResult: Encodable, Sendable {
    /// Base64 (standard alphabet) Ed25519 signature.
    public let signature: String
    /// Raw wallet address `0:<hex>`.
    public let address: String
    /// Unix seconds at signing time.
    public let timestamp: UInt64
    /// dApp domain (URL host, not encoded).
    public let domain: String
    /// The payload from the request, echoed verbatim.
    public let payload: TonConnectSignDataPayload

    public init(signature: Data, address: String, timestamp: UInt64, domain: String, payload: TonConnectSignDataPayload) {
        self.signature = signature.base64EncodedString()
        self.address = address
        self.timestamp = timestamp
        self.domain = domain
        self.payload = payload
    }
}

/// Wallet-initiated `disconnect` event (`spec/rpc.md`).
public struct TonConnectDisconnectEvent: Encodable, Equatable, Sendable {
    private struct Empty: Encodable, Equatable {}

    public let event = "disconnect"
    /// Monotonically increasing per session, independent from request ids.
    public let id: Int
    private let payload = Empty()

    public init(id: Int) {
        self.id = id
    }
}
