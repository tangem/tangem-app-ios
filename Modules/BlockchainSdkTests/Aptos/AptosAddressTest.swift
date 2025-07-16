//
//  AptosAddressTest.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import WalletCore
import CryptoKit
@testable import BlockchainSdk
import Testing

struct AptosAddressTest {
    @Test
    func defaultAddressGeneration() throws {
        // given
        let addressServiceFactory = AddressServiceFactory(blockchain: .aptos(curve: .ed25519_slip0010, testnet: false))
        let addressService = addressServiceFactory.makeAddressService()

        let privateKey = Data(hexString: "a6c4394041e64fe93d889386d7922af1b9a87f12e433762759608e61434d6cf7")

        let publicKey = try Curve25519.Signing.PrivateKey(rawRepresentation: privateKey)
            .publicKey
            .rawRepresentation
        let expectedAddress = "0x31f64c99e5a0e954271404bf5841e9cb8dbba0b1c25d79f6751e46762c446cc3"

        // when
        let address = try addressService.makeAddress(from: publicKey).value

        // then
        #expect(address == expectedAddress)
    }

    @Test
    func addressGeneration_anyCurve() throws {
        let addressServiceFactory = AddressServiceFactory(blockchain: .aptos(curve: .ed25519, testnet: false))
        let addressService = addressServiceFactory.makeAddressService()

        let address = try addressService.makeAddress(from: Keys.AddressesKeys.edKey).value
        let slipAddress = try addressService.makeAddress(from: Keys.AddressesKeys.edKey).value

        #expect(address == slipAddress)
    }

    @Test
    func invalidCurveGeneration_throwsError() async throws {
        let addressServiceFactory = AddressServiceFactory(blockchain: .aptos(curve: .ed25519_slip0010, testnet: false))
        let addressService = addressServiceFactory.makeAddressService()

        #expect(throws: (any Error).self) {
            try addressService.makeAddress(from: Keys.AddressesKeys.secpDecompressedKey)
        }
        #expect(throws: (any Error).self) {
            try addressService.makeAddress(from: Keys.AddressesKeys.secpCompressedKey)
        }
    }

    @Test(arguments: [
        "0x77b6ecc77530f2b7cad89abcdd8dfece24a9cba20acc608cee424f30d3721ea1",
        "0x7d7e436f0b2aafde60774efb26ccc432cf881b677aca7faaf2a01879bd19fb8",
        "0x68c709c6614e29f401b6bfdd0b89578381ef0fb719515c03b73cf13e45550e06",
        "0x8d2d7bcde13b2513617df3f98cdd5d0e4b9f714c6308b9204fe18ad900d92609",
    ])
    func addressValidation_validAddresses(address: String) throws {
        // given
        let addressServiceFactory = AddressServiceFactory(blockchain: .aptos(curve: .ed25519_slip0010, testnet: false))

        // when
        let addressService = addressServiceFactory.makeAddressService()

        // then
        #expect(addressService.validate(address))
    }

    @Test(arguments: [
        "0x7d7e436f0askdjaksldb2aafde60774efb26cccll432cf881b677aca7faaf2a01879bd19fb8",
        "me@0x1.com",
        "me@google.com",
        "x7d7e436f0askdjaksldb2aafde60774efb26cccll432cf881b677aca7faaf2a01879bd19fb8",
        "",
    ])
    func addressValidation_invalidAddresses(address: String) throws {
        // given
        let addressServiceFactory = AddressServiceFactory(blockchain: .aptos(curve: .ed25519_slip0010, testnet: false))

        // when
        let addressService = addressServiceFactory.makeAddressService()

        // then
        #expect(!addressService.validate(address))
    }
}
