//
//  SmartContractMethodTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import BigInt
@testable import BlockchainSdk
import Testing

struct SmartContractMethodTests {
    @Test
    func transferERC20TokenMethod() throws {
        // give
        let destination = "0x90e4d59c8583e37426b37d1d7394b6008a987c67"
        let amount = BigUInt("1000000")

        // when
        let data = TransferERC20TokenMethod(destination: destination, amount: amount).data

        // then
        let expectedData = [
            "a9059cbb",
            "00000000000000000000000090e4d59c8583e37426b37d1d7394b6008a987c67",
            "00000000000000000000000000000000000000000000000000000000000f4240",
        ]

        #expect(data.hex() == expectedData.joined().lowercased())
    }

    @Test
    func approveERC20TokenMethod() throws {
        // give
        let spender = "0x1111111254EEB25477B68fb85Ed929f73A960582"
        let amount = BigUInt("1000000")

        // when
        let data = ApproveERC20TokenMethod(spender: spender, amount: amount).data

        // then
        let expectedData = [
            "095ea7b3",
            "0000000000000000000000001111111254EEB25477B68fb85Ed929f73A960582",
            "00000000000000000000000000000000000000000000000000000000000f4240",
        ]

        #expect(data.hex() == expectedData.joined().lowercased())
    }

    @Test
    func allowanceERC20TokenMethod() throws {
        // give
        let owner = "0x90e4d59c8583e37426b37d1d7394b6008a987c67"
        let spender = "0x1111111254EEB25477B68fb85Ed929f73A960582"

        // when
        let data = AllowanceERC20TokenMethod(owner: owner, spender: spender).data

        // then
        let expectedData = [
            "dd62ed3e",
            "00000000000000000000000090e4d59c8583e37426b37d1d7394b6008a987c67",
            "0000000000000000000000001111111254EEB25477B68fb85Ed929f73A960582",
        ]

        #expect(data.hex() == expectedData.joined().lowercased())
    }

    @Test
    func tokenBalanceERC20TokenMethod() throws {
        // give
        let owner = "0x90e4d59c8583e37426b37d1d7394b6008a987c67"

        // when
        let data = TokenBalanceERC20TokenMethod(owner: owner).data

        // then
        let expectedData = [
            "70a08231",
            "00000000000000000000000090e4d59c8583e37426b37d1d7394b6008a987c67",
        ]

        #expect(data.hex() == expectedData.joined().lowercased())
    }

    // MARK: - ERC721 Tests

    @Test(arguments: [
        TransferERC721TokenMethodTestCase.baseCase,
        TransferERC721TokenMethodTestCase.largeTokenId,
        TransferERC721TokenMethodTestCase.zeroTokenId,
    ])
    func transferERC721TokenMethod(testCase: TransferERC721TokenMethodTestCase) throws {
        let source = "0x90e4d59c8583e37426b37d1d7394b6008a987c67"
        let destination = "0x1111111254EEB25477B68fb85Ed929f73A960582"

        let method = try TransferERC721TokenMethod(
            source: source,
            destination: destination,
            assetIdentifier: testCase.assetIdentifier
        )
        let data = method.data
        #expect(data.hex() == testCase.expectedHex.lowercased())
    }

    @Test
    func transferERC721TokenMethodWithInvalidAssetIdentifier() throws {
        // give
        let source = "0x90e4d59c8583e37426b37d1d7394b6008a987c67"
        let destination = "0x1111111254EEB25477B68fb85Ed929f73A960582"
        let assetIdentifier = "invalid_token_id"

        // when & then
        #expect(throws: TransferERC721TokenMethod.Error.invalidAssetIdentifier) {
            _ = try TransferERC721TokenMethod(
                source: source,
                destination: destination,
                assetIdentifier: assetIdentifier
            )
        }
    }

    // MARK: - ERC1155 Tests

    @Test(arguments: [
        TransferERC1155TokenMethodTestCase.baseCase,
        TransferERC1155TokenMethodTestCase.largeAmount,
        TransferERC1155TokenMethodTestCase.zeroAmount,
    ])
    func transferERC1155TokenMethod(testCase: TransferERC1155TokenMethodTestCase) throws {
        // give
        let source = "0x90e4d59c8583e37426b37d1d7394b6008a987c67"
        let destination = "0x1111111254EEB25477B68fb85Ed929f73A960582"
        let assetIdentifier = "12345"

        // when
        let method = try TransferERC1155TokenMethod(
            source: source,
            destination: destination,
            assetIdentifier: assetIdentifier,
            assetAmount: testCase.amount
        )
        let data = method.data

        // then
        #expect(data.hex() == testCase.expectedHex.lowercased())
    }

    @Test
    func transferERC1155TokenMethodWithInvalidAssetIdentifier() throws {
        // give
        let source = "0x90e4d59c8583e37426b37d1d7394b6008a987c67"
        let destination = "0x1111111254EEB25477B68fb85Ed929f73A960582"
        let assetIdentifier = "invalid_token_id"
        let assetAmount = BigUInt("100")

        // when & then
        #expect(throws: TransferERC1155TokenMethod.Error.invalidAssetIdentifier) {
            _ = try TransferERC1155TokenMethod(
                source: source,
                destination: destination,
                assetIdentifier: assetIdentifier,
                assetAmount: assetAmount
            )
        }
    }

    // MARK: - Method ID Tests

    @Test
    func erc721MethodIdIsCorrect() throws {
        // give
        let source = "0x90e4d59c8583e37426b37d1d7394b6008a987c67"
        let destination = "0x1111111254EEB25477B68fb85Ed929f73A960582"
        let assetIdentifier = "12345"

        // when
        let method = try TransferERC721TokenMethod(
            source: source,
            destination: destination,
            assetIdentifier: assetIdentifier
        )

        // then
        #expect(method.methodId == "0x42842e0e")
    }

    @Test
    func erc1155MethodIdIsCorrect() throws {
        // give
        let source = "0x90e4d59c8583e37426b37d1d7394b6008a987c67"
        let destination = "0x1111111254EEB25477B68fb85Ed929f73A960582"
        let assetIdentifier = "12345"
        let assetAmount = BigUInt("100")

        // when
        let method = try TransferERC1155TokenMethod(
            source: source,
            destination: destination,
            assetIdentifier: assetIdentifier,
            assetAmount: assetAmount
        )

        // then
        #expect(method.methodId == "0xf242432a")
    }

    // MARK: - Data Structure Tests

    @Test
    func erc721DataStructureIsCorrect() throws {
        // give
        let source = "0x90e4d59c8583e37426b37d1d7394b6008a987c67"
        let destination = "0x1111111254EEB25477B68fb85Ed929f73A960582"
        let assetIdentifier = "12345"

        // when
        let method = try TransferERC721TokenMethod(
            source: source,
            destination: destination,
            assetIdentifier: assetIdentifier
        )
        let data = method.data

        // then
        // Method ID (4 bytes) + source address (32 bytes) + destination address (32 bytes) + token ID (32 bytes)
        #expect(data.count == 4 + 32 + 32 + 32)
        #expect(data.prefix(4).hex() == "42842e0e")
    }

    @Test
    func erc1155DataStructureIsCorrect() throws {
        // give
        let source = "0x90e4d59c8583e37426b37d1d7394b6008a987c67"
        let destination = "0x1111111254EEB25477B68fb85Ed929f73A960582"
        let assetIdentifier = "12345"
        let assetAmount = BigUInt("100")

        // when
        let method = try TransferERC1155TokenMethod(
            source: source,
            destination: destination,
            assetIdentifier: assetIdentifier,
            assetAmount: assetAmount
        )
        let data = method.data

        // then
        // Method ID (4 bytes) + source address (32 bytes) + destination address (32 bytes) +
        // token ID (32 bytes) + amount (32 bytes) + bytes offset (32 bytes) + bytes data (32 bytes)
        #expect(data.count == 4 + 32 + 32 + 32 + 32 + 32 + 32)
        #expect(data.prefix(4).hex() == "f242432a")
    }
}
