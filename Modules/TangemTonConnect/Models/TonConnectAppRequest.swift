//
//  TonConnectAppRequest.swift
//  TangemModules
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// RPC methods a dApp may call after connecting (`spec/rpc.md`).
public enum TonConnectMethod: Equatable, Sendable {
    case sendTransaction
    case signMessage
    case signData
    case disconnect
    case unknown(String)

    public init(rawValue: String) {
        switch rawValue {
        case "sendTransaction": self = .sendTransaction
        case "signMessage": self = .signMessage
        case "signData": self = .signData
        case "disconnect": self = .disconnect
        default: self = .unknown(rawValue)
        }
    }

    public var rawValue: String {
        switch self {
        case .sendTransaction: return "sendTransaction"
        case .signMessage: return "signMessage"
        case .signData: return "signData"
        case .disconnect: return "disconnect"
        case .unknown(let name): return name
        }
    }
}

/// `AppRequest` — the decrypted plaintext of a dApp → wallet bridge message.
public struct TonConnectAppRequest: Decodable, Equatable, Sendable {
    public let method: TonConnectMethod
    /// Operation-specific parameters; for `sendTransaction`/`signData` a single JSON string.
    public let params: [String]
    /// Monotonically increasing per session; the wallet must reject non-increasing ids.
    public let id: String

    public init(method: TonConnectMethod, params: [String], id: String) {
        self.method = method
        self.params = params
        self.id = id
    }

    private enum CodingKeys: String, CodingKey {
        case method
        case params
        case id
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        method = TonConnectMethod(rawValue: try container.decode(String.self, forKey: .method))
        params = try container.decodeIfPresent([String].self, forKey: .params) ?? []

        // Some dApp SDKs send the id as a JSON number.
        if let string = try? container.decode(String.self, forKey: .id) {
            id = string
        } else {
            id = String(try container.decode(Int.self, forKey: .id))
        }
    }

    /// Decodes the plaintext of an incoming bridge message.
    public static func decode(from plaintext: Data) throws -> TonConnectAppRequest {
        do {
            return try JSONDecoder().decode(TonConnectAppRequest.self, from: plaintext)
        } catch {
            throw TonConnectError.malformedEnvelope("AppRequest is not valid JSON")
        }
    }

    /// The single JSON-string parameter carried by `sendTransaction`, `signMessage` and `signData`.
    public func singleJSONParameter() throws -> Data {
        guard params.count == 1 else {
            throw TonConnectError.badRequest("expected exactly one parameter, got \(params.count)")
        }
        return Data(params[0].utf8)
    }
}
