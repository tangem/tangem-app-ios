//
//  EthereumCompiledTransaction.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

public struct EthereumCompiledTransaction: Decodable, Hashable {
    public let from: String
    public let gasLimit: BigUInt
    public let to: String
    public let data: String
    public let nonce: Int
    public let type: Int
    public let maxFeePerGas: BigUInt?
    public let maxPriorityFeePerGas: BigUInt?
    public let gasPrice: BigUInt?
    public let chainId: Int
    public let value: BigUInt?

    public init(
        from: String,
        gasLimit: BigUInt,
        to: String,
        data: String,
        nonce: Int,
        type: Int,
        maxFeePerGas: BigUInt?,
        maxPriorityFeePerGas: BigUInt?,
        gasPrice: BigUInt?,
        chainId: Int,
        value: BigUInt?
    ) {
        self.from = from
        self.gasLimit = gasLimit
        self.to = to
        self.data = data
        self.nonce = nonce
        self.type = type
        self.maxFeePerGas = maxFeePerGas
        self.maxPriorityFeePerGas = maxPriorityFeePerGas
        self.gasPrice = gasPrice
        self.chainId = chainId
        self.value = value
    }

    private enum CodingKeys: CodingKey {
        case from
        case gasLimit
        case to
        case data
        case nonce
        case type
        case maxFeePerGas
        case maxPriorityFeePerGas
        case gasPrice
        case chainId
        case value
    }

    public init(from decoder: any Decoder) throws {
        let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)

        from = try container.decode(String.self, forKey: CodingKeys.from)

        let gasLimit = try container.decode(String.self, forKey: CodingKeys.gasLimit)
        self.gasLimit = BigUInt(Data(hex: gasLimit))

        to = try container.decode(String.self, forKey: CodingKeys.to)
        data = try container.decode(String.self, forKey: CodingKeys.data)
        nonce = try container.decode(Int.self, forKey: CodingKeys.nonce)
        type = try container.decode(Int.self, forKey: CodingKeys.type)

        let maxFeePerGas = try container.decodeIfPresent(String.self, forKey: CodingKeys.maxFeePerGas)
        self.maxFeePerGas = maxFeePerGas.flatMap { BigUInt(Data(hex: $0)) }

        let maxPriorityFeePerGas = try container.decodeIfPresent(String.self, forKey: CodingKeys.maxPriorityFeePerGas)
        self.maxPriorityFeePerGas = maxPriorityFeePerGas.flatMap { BigUInt(Data(hex: $0)) }

        let gasPrice = try container.decodeIfPresent(String.self, forKey: CodingKeys.gasPrice)
        self.gasPrice = gasPrice.flatMap { BigUInt(Data(hex: $0)) }

        chainId = try container.decode(Int.self, forKey: CodingKeys.chainId)

        let value = try container.decodeIfPresent(String.self, forKey: CodingKeys.value)
        self.value = value.flatMap { BigUInt(Data(hex: $0)) }
    }
}
