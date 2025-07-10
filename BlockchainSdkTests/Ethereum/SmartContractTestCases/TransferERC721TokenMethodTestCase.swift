//
//  Untitled.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BigInt

extension SmartContractMethodTests {
    struct TransferERC1155TokenMethodTestCase {
        let amount: BigUInt
        let expectedHex: String

        static let baseCase: Self = .init(
            amount: BigUInt("100"),
            expectedHex: [
                "f242432a", // method ID
                "00000000000000000000000090e4d59c8583e37426b37d1d7394b6008a987c67", // source address
                "0000000000000000000000001111111254EEB25477B68fb85Ed929f73A960582", // destination address
                "0000000000000000000000000000000000000000000000000000000000003039", // token ID (12345)
                "0000000000000000000000000000000000000000000000000000000000000064", // amount (100)
                "00000000000000000000000000000000000000000000000000000000000000a0", // bytes offset (160)
                "0000000000000000000000000000000000000000000000000000000000000000", // bytes length (32)
            ].joined()
        )

        static let largeAmount: Self = .init(
            amount: BigUInt("1" + String(repeating: "0", count: 24))!,
            expectedHex: [
                "f242432a", // method ID
                "00000000000000000000000090e4d59c8583e37426b37d1d7394b6008a987c67", // source address
                "0000000000000000000000001111111254EEB25477B68fb85Ed929f73A960582", // destination address
                "0000000000000000000000000000000000000000000000000000000000003039", // token ID (12345)
                "00000000000000000000000000000000000000000000d3c21bcecceda1000000", // amount (0)
                "00000000000000000000000000000000000000000000000000000000000000a0", // bytes offset (160)
                "0000000000000000000000000000000000000000000000000000000000000000", // bytes length (32)
            ].joined()
        )

        static let zeroAmount: Self = .init(
            amount: BigUInt("0"),
            expectedHex: [
                "f242432a", // method ID
                "00000000000000000000000090e4d59c8583e37426b37d1d7394b6008a987c67", // source address
                "0000000000000000000000001111111254EEB25477B68fb85Ed929f73A960582", // destination address
                "0000000000000000000000000000000000000000000000000000000000003039", // token ID (12345)
                "0000000000000000000000000000000000000000000000000000000000000000", // amount (0)
                "00000000000000000000000000000000000000000000000000000000000000a0", // bytes offset (160)
                "0000000000000000000000000000000000000000000000000000000000000000", // bytes length (32)
            ].joined()
        )
    }
}
