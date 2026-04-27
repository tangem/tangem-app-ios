//
//  EthereumNameServiceTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemSdk
@testable import BlockchainSdk

struct EthereumNameServiceTests {
    let processor = CommonENSProcessor()

    @Test
    func testConvertResponseToAddress() throws {
        // give
        let toConvertHex = "0x0000000000000000000000000000000000000000000000000000000000000040000000000000000000000000231b0ee14048e9dccd1d247744d114a4eb5e8e630000000000000000000000000000000000000000000000000000000000000020000000000000000000000000d8da6bf26964af9d7eed9e03e53415d37aa96045"

        // when
        let convertedAddress = try ENSResponseConverter.convert(toConvertHex)

        // then
        let expectedData = "0xd8da6bf26964af9d7eed9e03e53415d37aa96045"

        #expect(convertedAddress == expectedData.lowercased())
    }

    @Test
    func testNamehashVitalikEth() throws {
        // give
        let expected = "ee6c4522aab0003e8d14cd40a6af439055fd2577951148c14b6cea9a53475835"
        // when
        let hash = try processor.getNameHash("vitalik.eth")
        // then
        #expect(hash.hex() == expected)
    }

    @Test
    func testNamehashEnsEth() throws {
        // give
        let expected = "4e34d3a81dc3a20f71bbdf2160492ddaa17ee7e5523757d47153379c13cb46df"
        // when
        let hash = try processor.getNameHash("ens.eth")
        // then
        #expect(hash.hex() == expected)
    }

    @Test
    func testNamehashTest1Test() throws {
        // give
        let expected = "77872462a9b85d1988752518a048a2b55cb16623ff699e99f3f7ad5b4507c82c"
        // when
        let hash = try processor.getNameHash("test1.test")
        // then
        #expect(hash.hex() == expected)
    }

    @Test
    func testNamehashEmptyInputFails() throws {
        #expect(throws: (any Error).self) {
            _ = try processor.getNameHash("")
        }
    }

    @Test
    func testNamehashLeadingDotFails() throws {
        #expect(throws: (any Error).self) {
            _ = try processor.getNameHash(".eth")
        }
    }

    @Test
    func testNamehashInvalidCharacterFails() throws {
        #expect(throws: (any Error).self) {
            _ = try processor.getNameHash("ens?.eth")
        }
    }

    @Test
    func testNamehashUppercaseNormalization() throws {
        // give
        let expected = "4e34d3a81dc3a20f71bbdf2160492ddaa17ee7e5523757d47153379c13cb46df"
        // when
        let hash = try processor.getNameHash("ENS.ETH")
        // then
        #expect(hash.hex() == expected)
    }

    @Test
    func testReadEthereumAddressEIP137TokenMethodDataHex() throws {
        // give
        let nameBytes = Data(hexString: "07766974616c696b0365746800")
        let hashBytes = Data(hexString: "ee6c4522aab0003e8d14cd40a6af439055fd2577951148c14b6cea9a53475835")
        let method = ReadEthereumAddressEIP137TokenMethod(nameBytes: nameBytes, hashBytes: hashBytes)
        let expectedDataHex = "0x9061b923" +
            "0000000000000000000000000000000000000000000000000000000000000040" +
            "0000000000000000000000000000000000000000000000000000000000000080" +
            "000000000000000000000000000000000000000000000000000000000000000d" +
            "07766974616c696b036574680000000000000000000000000000000000000000" +
            "0000000000000000000000000000000000000000000000000000000000000024" +
            "3b3b57deee6c4522aab0003e8d14cd40a6af439055fd2577951148c14b6cea9a53475835"
        // when
        let dataHex = method.data.hex().addHexPrefix()
        // then
        #expect(dataHex.lowercased() == expectedDataHex.lowercased())
    }

    @Test
    func testENSResponseConverterExample1() throws {
        // give
        let result = "0x" +
            "0000000000000000000000000000000000000000000000000000000000000040" +
            "000000000000000000000000231b0ee14048e9dccd1d247744d114a4eb5e8e63" +
            "0000000000000000000000000000000000000000000000000000000000000020" +
            "000000000000000000000000d8da6bf26964af9d7eed9e03e53415d37aa96045"
        let expected = "0xd8da6bf26964af9d7eed9e03e53415d37aa96045"
        // when
        let actual = try ENSResponseConverter.convert(result)
        // then
        #expect(actual == expected)
    }

    @Test
    func testENSResponseConverterExample2() throws {
        // give
        let result = "0x" +
            "0000000000000000000000000000000000000000000000000000000000000030" +
            "4048e9dccd1d247744d114a4eb5e8e63" +
            "0000000000000000000000000000000000000000000000000000000000000020" +
            "000000000000000000000000d8da6bf26964af9d7eed9e03e53415d37aa96045"
        let expected = "0xd8da6bf26964af9d7eed9e03e53415d37aa96045"
        // when
        let actual = try ENSResponseConverter.convert(result)
        // then
        #expect(actual == expected)
    }

    @Test
    func testENSResponseConverterExample3() throws {
        // give
        let result = "0x" +
            "0000000000000000000000000000000000000000000000000000000000000030" +
            "4048e9dccd1d247744d114a4eb5e8e63" +
            "000000000000000000000000000000000000000000000000000000000000001E" +
            "00000000000000000000d8da6bf26964af9d7eed9e03e53415d37aa96045"
        let expected = "0xd8da6bf26964af9d7eed9e03e53415d37aa96045"
        // when
        let actual = try ENSResponseConverter.convert(result)
        // then
        #expect(actual == expected)
    }
}
