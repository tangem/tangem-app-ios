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
        let addressService = KaspaAddressService(isTestnet: false)

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

    @Test
    func addressComponentsAndValidation() throws {
        let addressService = KaspaAddressService(isTestnet: false)

        #expect(!addressService.validate("kaspb:qyp5ez9p4q6xnh0jp5xq0ewy58nmsde5uus7vrty9w222v3zc37xwrgeqhkq7v3"))
        #expect(!addressService.validate("kaspa:qyp5ez9p4q6xnh0jp5xq0ewy58nmsde5uus7vrty9w222v3zc37xwrgeqhkq7v4"))

        let ecdsaAddress = "kaspa:qyp4scvsxvkrjxyq98gd4xedhgrqtmf78l7wl8p8p4j0mjuvpwjg5cqhy97n472"
        let ecdsaAddressComponents = addressService.parse(ecdsaAddress)!
        #expect(addressService.validate(ecdsaAddress))
        #expect(ecdsaAddressComponents.hash == Data(hex: "03586190332c39188029d0da9b2dba0605ed3e3ffcef9c270d64fdcb8c0ba48a60"))
        #expect(ecdsaAddressComponents.type == .P2PK_ECDSA)

        let schnorrAddress = "kaspa:qpsqw2aamda868dlgqczeczd28d5nc3rlrj3t87vu9q58l2tugpjs2psdm4fv"
        let schnorrAddressComponents = addressService.parse(schnorrAddress)!
        #expect(addressService.validate(schnorrAddress))
        #expect(schnorrAddressComponents.hash == Data(hex: "60072BBDDB7A7D1DBF40302CE04D51DB49E223F8E5159FCCE14143FD4BE20328"))
        #expect(schnorrAddressComponents.type == .P2PK_Schnorr)

        let p2shAddress = "kaspa:pqurku73qluhxrmvyj799yeyptpmsflpnc8pha80z6zjh6efwg3v2rrepjm5r"
        let p2shAddressComponents = addressService.parse(p2shAddress)!
        #expect(addressService.validate(p2shAddress))
        #expect(p2shAddressComponents.hash == Data(hex: "383b73d107f9730f6c24bc5293240ac3b827e19e0e1bf4ef16852beb297222c5"))
        #expect(p2shAddressComponents.type == .P2SH)
    }
}
