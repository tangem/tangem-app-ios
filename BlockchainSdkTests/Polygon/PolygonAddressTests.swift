//
//  PolygonAddressTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
@testable import BlockchainSdk
import Testing
import WalletCore

struct PolygonAddressTests {
    @Test(arguments: [
        "0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d",
    ])
    func addressValidation_validAddresses(addressHex: String) {
        let addressValidator = AddressServiceFactory(blockchain: .polygon(testnet: false)).makeAddressService()
        #expect(addressValidator.validate(addressHex))
    }

    @Test
    func addressGeneration() throws {
        let blockchain = Blockchain.polygon(testnet: false)
        let service = AddressServiceFactory(blockchain: blockchain).makeAddressService()
        let addressesUtility = AddressServiceManagerUtility()

        let addr_dec = try service.makeAddress(from: Keys.AddressesKeys.secpDecompressedKey)
        let addr_comp = try service.makeAddress(from: Keys.AddressesKeys.secpCompressedKey)

        #expect(addr_dec.value == addr_comp.value)
        #expect(addr_dec.localizedName == addr_comp.localizedName)
        #expect(addr_dec.type == addr_comp.type)
        #expect(addr_dec.value == "0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d")
        #expect("0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d".lowercased() == "0x6eca00c52afc728cdbf42e817d712e175bb23c7d") // without checksum

        try #expect(addressesUtility.makeTrustWalletAddress(publicKey: Keys.AddressesKeys.secpDecompressedKey, for: blockchain) == addr_comp.value)
    }

    @Test
    func inavalidCurveGeneration_throwsError() throws {
        let service = AddressServiceFactory(blockchain: .polygon(testnet: false)).makeAddressService()
        #expect(throws: (any Error).self) {
            try service.makeAddress(from: Keys.AddressesKeys.edKey)
        }
    }
}
