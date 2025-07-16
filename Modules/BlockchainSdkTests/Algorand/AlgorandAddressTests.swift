//
//  AlgorandAddressTests.swift
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

struct AlgorandAddressTests {
    @Test
    func defaultAddressGeneration() throws {
        // given
        let addressServiceFactory = AddressServiceFactory(blockchain: .algorand(curve: .ed25519_slip0010, testnet: false))
        let addressService = addressServiceFactory.makeAddressService()
        let privateKey = Data(hexString: "a6c4394041e64fe93d889386d7922af1b9a87f12e433762759608e61434d6cf7")

        let publicKey = try Curve25519.Signing.PrivateKey(rawRepresentation: privateKey)
            .publicKey
            .rawRepresentation
        let expectedAddress = "ADIYK65L3XR5ODNNCUIQVEET455L56MRKJHRBX5GU4TZI2752QIWK4UL5A"

        // when
        let address = try addressService.makeAddress(from: publicKey).value

        // then
        #expect(address == expectedAddress)
    }

    @Test
    func addressGeneration_anyCurve() throws {
        let addressServiceFactory = AddressServiceFactory(blockchain: .algorand(curve: .ed25519, testnet: false))
        let addressService = addressServiceFactory.makeAddressService()
        let address = try addressService.makeAddress(from: Keys.AddressesKeys.edKey).value

        let slipAddressServiceFactory = AddressServiceFactory(blockchain: .algorand(curve: .ed25519_slip0010, testnet: false))
        let slipAddressService = addressServiceFactory.makeAddressService()
        let slipAddress = try addressService.makeAddress(from: Keys.AddressesKeys.edKey).value

        #expect(address == slipAddress)
    }

    @Test
    func invalidCurveGeneration_throwsError() async throws {
        let addressServiceFactory = AddressServiceFactory(blockchain: .algorand(curve: .ed25519_slip0010, testnet: false))
        let addressService = addressServiceFactory.makeAddressService()

        #expect(throws: (any Error).self) {
            try addressService.makeAddress(from: Keys.AddressesKeys.secpDecompressedKey)
        }
        #expect(throws: (any Error).self) {
            try addressService.makeAddress(from: Keys.AddressesKeys.secpCompressedKey)
        }
    }

    @Test(arguments: [
        "ZW3ISEHZUHPO7OZGMKLKIIMKVICOUDRCERI454I3DB2BH52HGLSO67W754",
        "Q7AUUQCAO3O6CLPHMPTWN3VTCWLLWZJSI6QDO5XEC4ZZR5JZWXWZL5YWOM",
        "ZMORINNT75RZ67ZWV2EGZYW6MKZ2LOSSB5VTKJON6NSPO5MW6TVCMXMVTU",
        "ZW3ISEHZUHPO7OZGMKLKIIMKVICOUDRCERI454I3DB2BH52HGLSO67W754",
    ])
    func addressValidation_validAddresses(address: String) throws {
        let addressServiceFactory = AddressServiceFactory(blockchain: .algorand(curve: .ed25519_slip0010, testnet: false))
        let addressService = addressServiceFactory.makeAddressService()
        #expect(addressService.validate(address))
    }

    @Test(arguments: [
        "ZW3ISEHZUHPO7OZGMKLKIIMKVICOUDRCERI454I3DB2BH52HGL",
        "EEQKMHD64P5FN25Y6W63ZHEPVCQZKM4PCMF6ZIIJW4IPFX4WJALA",
        "44bc93A8d3cEfA5a6721723a2f8d2e4F7d480BA0",
        "0xf3d468DBb386aaD46E92FF222adDdf872C8CC06",
        "0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d1",
        "me@google.com",
        "",
    ])
    func addressValidation_invalidAddresses(address: String) throws {
        let addressServiceFactory = AddressServiceFactory(blockchain: .algorand(curve: .ed25519_slip0010, testnet: false))
        let addressService = addressServiceFactory.makeAddressService()
        #expect(!addressService.validate(address))
    }
}
