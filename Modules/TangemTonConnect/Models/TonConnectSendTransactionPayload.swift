//
//  TonConnectSendTransactionPayload.swift
//  TangemModules
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Wire shape of `params[0]` for `sendTransaction` and `signMessage` (`spec/rpc.md`), before validation.
///
/// Only presence of `items` is recorded: structured items are not supported by this wallet, and a
/// payload carrying them is rejected with `BAD_REQUEST` by `TonConnectSendTransactionValidator`.
public struct TonConnectSendTransactionPayload: Decodable, Equatable, Sendable {
    public struct Message: Decodable, Equatable, Sendable {
        /// Destination in user-friendly form (raw `wc:hex` form must be rejected).
        public let address: String
        /// Nanocoins as a decimal string.
        public let amount: String
        /// Base64 single-root BoC.
        public let payload: String?
        /// Base64 single-root BoC.
        public let stateInit: String?
        public let extraCurrency: [String: String]?

        public init(address: String, amount: String, payload: String? = nil, stateInit: String? = nil, extraCurrency: [String: String]? = nil) {
            self.address = address
            self.amount = amount
            self.payload = payload
            self.stateInit = stateInit
            self.extraCurrency = extraCurrency
        }

        private enum CodingKeys: String, CodingKey {
            case address
            case amount
            case payload
            case stateInit
            case extraCurrency = "extra_currency"
        }
    }

    public let validUntil: Int64?
    public let network: TonConnectNetworkID?
    public let from: String?
    public let messages: [Message]?
    public let hasItems: Bool

    public init(validUntil: Int64?, network: TonConnectNetworkID?, from: String?, messages: [Message]?, hasItems: Bool = false) {
        self.validUntil = validUntil
        self.network = network
        self.from = from
        self.messages = messages
        self.hasItems = hasItems
    }

    private enum CodingKeys: String, CodingKey {
        case validUntil = "valid_until"
        case network
        case from
        case messages
        case items
    }

    /// Consumes any JSON value without interpreting it.
    private struct OpaqueValue: Decodable {
        init(from decoder: any Decoder) throws {}
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // `valid_until` is an integer, but some SDKs emit it as a numeric string.
        if let number = try? container.decodeIfPresent(Int64.self, forKey: .validUntil) {
            validUntil = number
        } else if let string = try? container.decodeIfPresent(String.self, forKey: .validUntil) {
            guard let number = Int64(string) else {
                throw DecodingError.dataCorruptedError(forKey: .validUntil, in: container, debugDescription: "valid_until is not an integer")
            }
            validUntil = number
        } else {
            validUntil = nil
        }

        network = try container.decodeIfPresent(TonConnectNetworkID.self, forKey: .network)
        from = try container.decodeIfPresent(String.self, forKey: .from)
        messages = try container.decodeIfPresent([Message].self, forKey: .messages)
        hasItems = try container.decodeIfPresent([OpaqueValue].self, forKey: .items) != nil
    }

    public static func decode(from json: Data) throws -> TonConnectSendTransactionPayload {
        do {
            return try JSONDecoder().decode(TonConnectSendTransactionPayload.self, from: json)
        } catch {
            throw TonConnectError.badRequest("transaction payload is not valid JSON")
        }
    }
}
