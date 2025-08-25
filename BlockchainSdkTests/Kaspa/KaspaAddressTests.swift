//
//  KaspaAddressTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import CryptoKit
import class WalletCore.PrivateKey
@testable import BlockchainSdk
import Testing

struct KaspaAddressTests {
    @Test
    func addressGeneration() throws {
        let addressService = AddressServiceFactory(blockchain: .kaspa(testnet: false)).makeAddressService()

        let expectedAddress = "kaspa:qypyrhxkfd055qulcvu6zccq4qe63qajrzgf7t4u4uusveguw6zzc3grrceeuex"
        let addressFromDecompressedKey = try addressService.makeAddress(from: Keys.AddressesKeys.secpDecompressedKey).value
        let addressFromCompressedKey = try addressService.makeAddress(from: Keys.AddressesKeys.secpCompressedKey).value

        #expect(addressFromCompressedKey == expectedAddress)
        #expect(addressFromDecompressedKey == expectedAddress)

        // https://github.com/kaspanet/kaspad/pull/2202/files
        // https://github.com/kaspanet/kaspad/blob/dev/util/address_test.go
        let kaspaTestPublicKey = Data([
            0x02, 0xf1, 0xd3, 0x78, 0x05, 0x46, 0xda, 0x20, 0x72, 0x8e, 0xa8, 0xa1, 0xf5, 0xe5, 0xe5, 0x1b, 0x84, 0x38, 0x00, 0x2c, 0xd7, 0xc8, 0x38, 0x2a, 0xaf, 0xa7, 0xdd, 0xf6, 0x80, 0xe1, 0x25, 0x57, 0xe4,
        ])
        let kaspaTestAddress = "kaspa:qyp0r5mcq4rd5grj3652ra09u5dcgwqq9ntuswp247nama5quyj40eq03sc2dkx"
        let addressFromKaspaPubKey = try addressService.makeAddress(from: kaspaTestPublicKey).value
        #expect(addressFromKaspaPubKey == kaspaTestAddress)

        #expect(throws: (any Error).self) {
            try addressService.makeAddress(from: Keys.AddressesKeys.edKey)
        }
    }
}
