//
//  SmartContractMethodTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
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
        let data = try TransferERC20TokenMethod(destination: destination, amount: amount).data

        // then
        let expectedData = [
            "a9059cbb",
            "00000000000000000000000090e4d59c8583e37426b37d1d7394b6008a987c67",
            "00000000000000000000000000000000000000000000000000000000000f4240",
        ]

        #expect(data.hex() == expectedData.joined().lowercased())
    }

    @Test(arguments: [
        "",
        "0x",
        "0x90e4d59c8583e37426b37d1d7394b6008a987c6", // 39 characters
        "0x90e4d59c8583e37426b37d1d7394b6008a987c677", // 41 characters
        "0x90e4d59c8583e37426b37d1d7394b6008a987czz", // non-hex characters
    ])
    func transferERC20TokenMethodRejectsBrokenDestination(destination: String) {
        #expect(throws: SmartContractAddress.Error.invalidAddress) {
            _ = try TransferERC20TokenMethod(destination: destination, amount: BigUInt("1000000"))
        }
    }

    @Test(arguments: EVMAddressUtils.Constants.burnAddresses)
    func transferERC20TokenMethodRejectsBurnDestination(destination: String) {
        #expect(throws: SmartContractAddress.Error.burnAddress) {
            _ = try TransferERC20TokenMethod(destination: destination, amount: BigUInt("1000000"))
        }
    }

    // MARK: - ERC20 transfer decoding

    @Test("Decodes the arguments of a transfer call")
    func transferERC20TokenMethodDecoding() throws {
        // give
        let calldata = Data(hex: [
            "a9059cbb",
            "00000000000000000000000090e4d59c8583e37426b37d1d7394b6008a987c67",
            "00000000000000000000000000000000000000000000000000000000000f4240",
        ].joined())

        // when
        let transfer = TransferERC20TokenMethod.parse(calldata: calldata)

        // then
        #expect(transfer?.destination == "0x90e4d59c8583e37426b37d1d7394b6008a987c67")
        #expect(transfer?.amount == BigUInt("1000000"))
    }

    @Test("Decoding an encoded transfer returns the original arguments")
    func transferERC20TokenMethodDecodingRoundTrip() throws {
        // give
        let destination = "0x1111111254eeb25477b68fb85ed929f73a960582"
        let amount = BigUInt("123456789012345678901234567890")

        // when
        let encoded = try TransferERC20TokenMethod(destination: destination, amount: amount).data
        let decoded = TransferERC20TokenMethod.parse(calldata: encoded)

        // then
        #expect(decoded?.destination == destination)
        #expect(decoded?.amount == amount)
    }

    @Test("Decodes a transfer of a zero amount")
    func transferERC20TokenMethodDecodingZeroAmount() throws {
        // give
        let destination = "0x90e4d59c8583e37426b37d1d7394b6008a987c67"

        // when
        let encoded = try TransferERC20TokenMethod(destination: destination, amount: .zero).data
        let decoded = TransferERC20TokenMethod.parse(calldata: encoded)

        // then
        #expect(decoded?.destination == destination)
        #expect(decoded?.amount == .zero)
    }

    @Test("Decodes a transfer of the largest representable amount")
    func transferERC20TokenMethodDecodingMaxAmount() throws {
        // give
        let destination = "0x90e4d59c8583e37426b37d1d7394b6008a987c67"
        let amount = BigUInt(Data(repeating: 0xFF, count: 32))

        // when
        let encoded = try TransferERC20TokenMethod(destination: destination, amount: amount).data
        let decoded = TransferERC20TokenMethod.parse(calldata: encoded)

        // then
        #expect(encoded.count == 68)
        #expect(decoded?.destination == destination)
        #expect(decoded?.amount == amount)
    }

    @Test("Recognizes a transfer call by its method id")
    func transferERC20TokenMethodIsEncodedCall() throws {
        // give
        let destination = "0x90e4d59c8583e37426b37d1d7394b6008a987c67"
        let amount = BigUInt("1000000")

        let transferCalldata = try TransferERC20TokenMethod(destination: destination, amount: amount).data
        let approveCalldata = ApproveERC20TokenMethod(spender: destination, amount: amount).data

        // then
        #expect(TransferERC20TokenMethod.isEncodedCall(transferCalldata))
        #expect(!TransferERC20TokenMethod.isEncodedCall(approveCalldata))
        #expect(!TransferERC20TokenMethod.isEncodedCall(Data()))
    }

    @Test("Rejects calldata that is not a well-formed transfer call", arguments: [
        TransferERC20TokenMethodDecodingRejectionTestCase.approveInsteadOfTransfer,
        TransferERC20TokenMethodDecodingRejectionTestCase.empty,
        TransferERC20TokenMethodDecodingRejectionTestCase.methodIdOnly,
        TransferERC20TokenMethodDecodingRejectionTestCase.truncatedArguments,
        TransferERC20TokenMethodDecodingRejectionTestCase.trailingBytes,
        TransferERC20TokenMethodDecodingRejectionTestCase.dirtyAddressSlot,
        TransferERC20TokenMethodDecodingRejectionTestCase.burnAddressDestination,
    ])
    func transferERC20TokenMethodDecodingRejection(testCase: TransferERC20TokenMethodDecodingRejectionTestCase) throws {
        #expect(TransferERC20TokenMethod.parse(calldata: testCase.calldata) == nil)
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

    @Test("Decodes the arguments of an approve call")
    func approveERC20TokenMethodDecoding() throws {
        // give
        let calldata = Data(hex: [
            "095ea7b3",
            "0000000000000000000000001231deb6f5749ef6ce6943a275a1d3e7486f4eae",
            "0000000000000000000000000000000000000000000000000000000001ab3f00",
        ].joined())

        // when
        let method = ApproveERC20TokenMethod(calldata: calldata)

        // then
        #expect(method?.spender == "0x1231deb6f5749ef6ce6943a275a1d3e7486f4eae")
        #expect(method?.amount == BigUInt("28000000"))
        #expect(method?.isUnlimited == false)
    }

    @Test("Decoding an encoded approve returns the original arguments")
    func approveERC20TokenMethodDecodingRoundTrip() throws {
        // give
        let spender = "0x1111111254eeb25477b68fb85ed929f73a960582"
        let amount = BigUInt("123456789012345678901234567890")

        // when
        let encoded = ApproveERC20TokenMethod(spender: spender, amount: amount).data
        let decoded = ApproveERC20TokenMethod(calldata: encoded)

        // then
        #expect(decoded?.spender == spender)
        #expect(decoded?.amount == amount)
    }

    @Test("Recognizes the uint256 maximum as an unlimited allowance")
    func approveERC20TokenMethodDecodingUnlimited() throws {
        // give
        let calldata = Data(hex: [
            "095ea7b3",
            "0000000000000000000000001231deb6f5749ef6ce6943a275a1d3e7486f4eae",
            "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
        ].joined())

        // when
        let method = ApproveERC20TokenMethod(calldata: calldata)

        // then
        #expect(method?.isUnlimited == true)
        #expect(method?.amount == BigUInt.maxUInt256)
    }

    @Test("Decodes an approve revoking an allowance")
    func approveERC20TokenMethodDecodingZeroAmount() throws {
        // give
        let spender = "0x90e4d59c8583e37426b37d1d7394b6008a987c67"

        // when
        let encoded = ApproveERC20TokenMethod(spender: spender, amount: .zero).data
        let decoded = ApproveERC20TokenMethod(calldata: encoded)

        // then
        #expect(decoded?.amount == .zero)
        #expect(decoded?.isUnlimited == false)
    }

    @Test("Rejects calldata that is not a well-formed approve call", arguments: [
        // A transfer carries the same argument shape, so only the method id tells them apart.
        ["a9059cbb", "00000000000000000000000090e4d59c8583e37426b37d1d7394b6008a987c67", "00000000000000000000000000000000000000000000000000000000000f4240"],
        [],
        ["095ea7b3"],
        // Amount slot one byte short.
        ["095ea7b3", "00000000000000000000000090e4d59c8583e37426b37d1d7394b6008a987c67", "00000000000000000000000000000000000000000000000000000000000f42"],
        // Extra slot after the arguments.
        ["095ea7b3", "00000000000000000000000090e4d59c8583e37426b37d1d7394b6008a987c67", "00000000000000000000000000000000000000000000000000000000000f4240", "0000000000000000000000000000000000000000000000000000000000000001"],
        // Non-zero padding in the spender slot.
        ["095ea7b3", "00000000000000000000002290e4d59c8583e37426b37d1d7394b6008a987c67", "00000000000000000000000000000000000000000000000000000000000f4240"],
    ])
    func approveERC20TokenMethodDecodingRejection(hex: [String]) throws {
        #expect(ApproveERC20TokenMethod(calldata: Data(hex: hex.joined())) == nil)
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
