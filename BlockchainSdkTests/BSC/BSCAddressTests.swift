//
//  BSCAddressTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
@testable import BlockchainSdk
import Testing
import enum WalletCore.CoinType

struct BSCAddressTests {
    private let addressesUtility = AddressServiceManagerUtility()

    @Test
    func defaultAddressGeneration() throws {
        let blockchain = Blockchain.bsc(testnet: false)
        let service = AddressServiceFactory(blockchain: blockchain).makeAddressService()

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
    func testnetAddressGeneration() throws {
        let blockchain = Blockchain.ethereum(testnet: false)
        let service = AddressServiceFactory(blockchain: blockchain).makeAddressService()

        let addr_dec = try service.makeAddress(from: Keys.AddressesKeys.secpDecompressedKey)
        let addr_comp = try service.makeAddress(from: Keys.AddressesKeys.secpCompressedKey)

        #expect(addr_dec.value == addr_comp.value)
        #expect(addr_dec.localizedName == addr_comp.localizedName)
        #expect(addr_dec.value == "0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d")
        #expect("0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d".lowercased() == "0x6eca00c52afc728cdbf42e817d712e175bb23c7d") // without checksum
    }

    @Test
    func inavalidCurveGeneration_throwsError() async throws {
        let blockchain = Blockchain.bsc(testnet: false)
        let service = AddressServiceFactory(blockchain: blockchain).makeAddressService()
        #expect(throws: (any Error).self) {
            try service.makeAddress(from: Keys.AddressesKeys.edKey)
        }
    }

    @Test(arguments: [
        "0xf3d468DBb386aaD46E92FF222adDdf872C8CC064",
    ])
    func addressValidation_validAddresses(addressHex: String) {
        let addressValidator = AddressServiceFactory(blockchain: .bsc(testnet: false)).makeAddressService()
        #expect(addressValidator.validate(addressHex))
    }
}
