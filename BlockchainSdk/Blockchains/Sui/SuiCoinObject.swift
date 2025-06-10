//
// SuiCoinObject.swift
// BlockchainSdk
//
// Created by [REDACTED_AUTHOR]
// Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct SuiCoinObject {
    let coinType: CoinType
    let coinObjectId: String
    let version: UInt64
    let digest: String
    let balance: Decimal

    static func from(_ response: SuiGetCoins.Coin) throws -> Self {
        guard let version = Decimal(stringValue: response.version)?.uint64Value,
              let balance = Decimal(stringValue: response.balance) else {
            throw SuiError.failedDecoding
        }

        return try SuiCoinObject(
            coinType: .init(string: response.coinType),
            coinObjectId: response.coinObjectId,
            version: version,
            digest: response.digest,
            balance: balance
        )
    }
}

extension SuiCoinObject {
    struct CoinType: Codable, Hashable {
        let contract: String
        let lowerID: String
        let upperID: String

        var string: String {
            [contract, lowerID, upperID].joined(separator: Self.separator)
        }

        static let sui = Self(contract: "0x2", lowerID: "sui", upperID: "SUI")
        private static let separator = "::"

        init(contract: String, lowerID: String, upperID: String) {
            self.contract = contract
            self.lowerID = lowerID
            self.upperID = upperID
        }

        init(string: String) throws {
            let elements = string.components(separatedBy: Self.separator)

            guard elements.count == 3 else {
                throw SuiError.failedDecoding
            }

            contract = Data(hexString: elements[0]).leadingZeroPadding(toLength: 32).hex().addHexPrefix()
            lowerID = elements[1]
            upperID = elements[2]
        }

        init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            try self.init(string: string)
        }

        func encode(to encoder: any Encoder) throws {
            try string.encode(to: encoder)
        }
    }
}
