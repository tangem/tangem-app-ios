//
//  TonConnectNetworkID.swift
//  TangemModules
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// TON network `global_id` as carried on every `network` field of TON Connect (`-239` mainnet, `-3` testnet).
///
/// The spec requires wallets to treat the value as an opaque identifier and to enforce exact string
/// equality against the active wallet network — never to special-case unknown values.
public struct TonConnectNetworkID: RawRepresentable, Hashable, Codable, Sendable, CustomStringConvertible {
    public static let mainnet = TonConnectNetworkID(rawValue: "-239")
    public static let testnet = TonConnectNetworkID(rawValue: "-3")

    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        // Some SDKs historically serialised the numeric id as a JSON number; accept both spellings.
        if let string = try? container.decode(String.self) {
            rawValue = string
        } else {
            rawValue = String(try container.decode(Int.self))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    public var description: String { rawValue }
}
