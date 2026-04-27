//
//  TransferERC1155TokenMethodTestCase.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

extension SmartContractMethodTests {
    struct TransferERC721TokenMethodTestCase {
        let assetIdentifier: String
        let expectedHex: String

        static let baseCase: Self = .init(
            assetIdentifier: "12345",
            expectedHex: [
                "42842e0e", // method ID
                "00000000000000000000000090e4d59c8583e37426b37d1d7394b6008a987c67", // source address
                "0000000000000000000000001111111254EEB25477B68fb85Ed929f73A960582", // destination address
                "0000000000000000000000000000000000000000000000000000000000003039", // token ID (12345)
            ].joined()
        )

        static let largeTokenId: Self = .init(
            assetIdentifier: "115792089237316195423570985008687907853269984665640564039457584007913129639935", // max uint256
            expectedHex: [
                "42842e0e", // method ID
                "00000000000000000000000090e4d59c8583e37426b37d1d7394b6008a987c67", // source address
                "0000000000000000000000001111111254EEB25477B68fb85Ed929f73A960582", // destination address
                "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff", // max uint256
            ].joined()
        )

        static let zeroTokenId: Self = .init(
            assetIdentifier: "0",
            expectedHex: [
                "42842e0e", // method ID
                "00000000000000000000000090e4d59c8583e37426b37d1d7394b6008a987c67", // source address
                "0000000000000000000000001111111254EEB25477B68fb85Ed929f73A960582", // destination address
                "0000000000000000000000000000000000000000000000000000000000000000", // token ID (0)
            ].joined()
        )
    }
}
