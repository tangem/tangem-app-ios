//
//  FilecoinAddressTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
@testable import BlockchainSdk
import Testing

struct FilecoinAddressTests {
    private let addressService = WalletCoreAddressService(blockchain: .filecoin)

    @Test
    func defaultAddressGeneration() throws {
        let publicKey = Data(hex: "038A3F02BEBAFD04C1FA82184BA3950C801015A0B61A0922110D7CEE42A2A13763")
        let expectedAddress = "f1hbyibpq4mea6l3no7aag24hxpwgf4zwp6msepwi"

        let address = try addressService.makeAddress(from: publicKey).value
        #expect(address == expectedAddress)
    }

    @Test
    func addressGeneration() throws {
        let defaultAddressGeneration2 = Blockchain.filecoin

        let compressedKeyAddress = try addressService.makeAddress(from: Keys.AddressesKeys.secpCompressedKey, type: .default)
        let decompressedKeyAddress = try addressService.makeAddress(from: Keys.AddressesKeys.secpDecompressedKey, type: .default)

        #expect(compressedKeyAddress.value == "f1zwodzyss6fjhvx5uoyc2dbk4yfruvhnsj3q4m6a")
        #expect(compressedKeyAddress.value == decompressedKeyAddress.value)

        #expect(throws: (any Error).self) {
            try addressService.makeAddress(from: Keys.AddressesKeys.edKey)
        }
    }

    @Test(.serialized, arguments: [
        "f15ihq5ibzwki2b4ep2f46avlkrqzhpqgtga7pdrq",
        "f12fiakbhe2gwd5cnmrenekasyn6v5tnaxaqizq6a",
        "f1wbxhu3ypkuo6eyp6hjx6davuelxaxrvwb2kuwva",
        "f17uoq6tp427uzv7fztkbsnn64iwotfrristwpryy",
    ])
    func addressIsValid(addressHex: String) throws {
        #expect(addressService.validate(addressHex))
    }

    @Test(.serialized, arguments: [
        "f0-1",
        "f018446744073709551616",
        "f4f77777777vnmsana",
        "t15ihq5ibzwki2b4ep2f46avlkrqzhpqgtga7pdrq",
        "f15ihq5ibzwki2b4ep2f46avlkr\0zhpqgtga7pdrq",
        "a15ihq5ibzwki2b4ep2f46avlkrqzhpqgtga7pdrq",
        "f95ihq5ibzwki2b4ep2f46avlkrqzhpqgtga7pdrq",
        "f15ihq5ibzwki2b4ep2f46avlkrqzhpqgtga7rdrr",
        "f24vg6ut43yw2h2jqydgbg2xq7x6f4kub3bg6as66",
        "f3vvmn62lofvhjd2ugzca6sof2j2ubwok6cj4xxbfzz4yuxfkgobpihhd2thlanmsh3w2ptld2gqkn2jvlss44",
        "f0vvmn62lofvhjd2ugzca6sof2j2ubwok6cj4xxbfzz4yuxfkgobpihhd2thlanmsh3w2ptld2gqkn2jvlss44",
        "f410f2oekwcmo2pueydmaq53eic2i62crtbeyuzx2gma",
    ])
    func addressIsInvalid(addressHex: String) throws {
        #expect(!addressService.validate(addressHex))
    }
}
