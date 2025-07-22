//
//  SuiAddressServiceTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import BlockchainSdk

struct SuiAddressTests {
    let addressService = AddressServiceFactory(blockchain: .sui(curve: .ed25519_slip0010, testnet: false)).makeAddressService()

    @Test
    func addressGeneration() throws {
        let address = try addressService.makeAddress(from: Keys.AddressesKeys.edKey, type: .default)

        #expect("0x690ff08b9f2fb93c928cdf2c387dc66145bdc2b9849e1999730a2f2f9cd51490" == address.value)

        #expect(throws: (any Error).self) {
            try addressService.makeAddress(from: Keys.AddressesKeys.secpCompressedKey)
        }

        #expect(throws: (any Error).self) {
            try addressService.makeAddress(from: Keys.AddressesKeys.secpDecompressedKey)
        }
    }

    @Test
    func makeAddressCreatesCorrectAddressValue() throws {
        let seedKey = Data(hex: "85ebd1441fe4f954fbe5dc6077bf008e119a5e269297c6f7083d001d2ac876fe")
        let walletPublicKey = Wallet.PublicKey(seedKey: seedKey, derivationType: nil)
        let expectedAddressValue = "0x54e80d76d790c277f5a44f3ce92f53d26f5894892bf395dee6375988876be6b2"
        let address = try addressService.makeAddress(for: walletPublicKey, with: .default)

        #expect(address.value == expectedAddressValue)
    }

    @Test(arguments: [
        "0x54e80d76d790c277f5a44f3ce92f53d26f5894892bf395dee6375988876be6b2", // 32 bytes address
    ])
    func validateShouldSucceedForCorrectAddress(address: String) {
        #expect(addressService.validate(address))
    }

    @Test(arguments: [
        "",
        "0x00", // invalidAddressOfOneByte
        "0x000000000000000000000000000000000000000000000000000000000000000", // invalidAddressOf65Chars
        "KsyS8YwkagyWZsQeMYNbf7Si9QkFZy1ZkK7ARqoqxAsjtFgGGxMqkKEPGg7GbhiRg4jhfb7RgU1fxdxaycd6F52qTf" // invalidBase58StringAddress
    ])
    func validateShouldFailForInvalidAddress(invalidAddress: String) {
        #expect(!addressService.validate(invalidAddress))
    }
}
