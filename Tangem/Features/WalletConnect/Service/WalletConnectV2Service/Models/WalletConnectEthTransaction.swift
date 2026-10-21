//
//  WalletConnectEthTransaction.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct WalletConnectEthTransaction: Codable {
    let from: String // Required
    let to: String // Required
    let value: String? // Required
    let data: String? // Required
    let gas: String?
    let gasPrice: String?
    let nonce: String?
    let chainId: String?

    var description: String {
        let data = data ?? ""

        return """
        to: \(to),
        value: \(value ?? "0"),
        gasPrice: \(gasPrice ?? "not specified"),
        data: \(data.count > 30 ? "\(data.prefix(10))...\(data.suffix(10))" : data),
        nonce: \(nonce ?? "not specified")
        """
    }
}

extension WalletConnectEthTransaction {
    init(from transaction: WalletConnectEthTransaction, gas: String? = nil, gasPrice: String? = nil) {
        from = transaction.from
        to = transaction.to
        value = transaction.value
        data = transaction.data
        self.gas = gas ?? transaction.gas
        self.gasPrice = gasPrice ?? transaction.gasPrice
        nonce = transaction.nonce
        chainId = transaction.chainId
    }
}

// MARK: - Decodable

extension WalletConnectEthTransaction {
    private enum CodingKeys: String, CodingKey {
        case from
        case to
        case value
        case data
        case gas
        case gasPrice
        case nonce
        case chainId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        from = try container.decode(String.self, forKey: .from)
        to = try container.decode(String.self, forKey: .to)
        value = try container.decodeIfPresent(String.self, forKey: .value)
        data = try container.decodeIfPresent(String.self, forKey: .data)
        gas = try container.decodeIfPresent(String.self, forKey: .gas)
        gasPrice = try container.decodeIfPresent(String.self, forKey: .gasPrice)
        nonce = try container.decodeIfPresent(String.self, forKey: .nonce)
        chainId = Self.decodeChainId(from: container)
    }

    var carriesCallData: Bool {
        guard let data else { return false }

        return !data.removeHexPrefix().isEmpty
    }

    var declaredChainId: Int? {
        guard let chainId else { return nil }

        if chainId.hasHexPrefix() {
            return Int(chainId.removeHexPrefix(), radix: 16)
        }

        return Int(chainId)
    }

    private static func decodeChainId(from container: KeyedDecodingContainer<CodingKeys>) -> String? {
        if let string = try? container.decodeIfPresent(String.self, forKey: .chainId) {
            return string
        }

        if let number = try? container.decodeIfPresent(Int.self, forKey: .chainId) {
            return String(number)
        }

        return nil
    }
}
