//
//  BitcoinCashAddressTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import class WalletCore.PrivateKey
import enum WalletCore.CoinType
@testable import BlockchainSdk
import Testing

struct BitcoinCashAddressTests {
    private let addressesUtility = AddressServiceManagerUtility()
    private let service = AddressServiceFactory(blockchain: .bitcoinCash).makeAddressService()

    @Test
    func defaultAddressGeneration() throws {
        let blockchain = Blockchain.bitcoinCash
        let addr_dec_default = try service.makeAddress(from: Keys.AddressesKeys.secpDecompressedKey, type: .default)
        let addr_comp_default = try service.makeAddress(from: Keys.AddressesKeys.secpCompressedKey, type: .default)

        #expect(addr_dec_default.value == addr_comp_default.value)

        #expect(addr_dec_default.localizedName == addr_comp_default.localizedName)

        #expect(addr_dec_default.type == addr_comp_default.type)

        let testRemovePrefix = String("bitcoincash:qrpgfcqrnqvp33vsex0clktvae2pqjfxnyxq0ml0zc".removeBchPrefix())
        #expect(testRemovePrefix == "qrpgfcqrnqvp33vsex0clktvae2pqjfxnyxq0ml0zc")

        #expect(addr_comp_default.value == "bitcoincash:qrpgfcqrnqvp33vsex0clktvae2pqjfxnyxq0ml0zc") // we ignore uncompressed addresses

        try #expect(addressesUtility.makeTrustWalletAddress(publicKey: Keys.AddressesKeys.secpDecompressedKey, for: blockchain) == addr_comp_default.value)
    }

    @Test
    func defaultAddressGeneration_Legacy() throws {
        let addr_dec_legacy = try service.makeAddress(from: Keys.AddressesKeys.secpDecompressedKey, type: .legacy)
        let addr_comp_legacy = try service.makeAddress(from: Keys.AddressesKeys.secpCompressedKey, type: .legacy)

        #expect(addr_dec_legacy.value == addr_comp_legacy.value)
        #expect(addr_dec_legacy.localizedName == addr_comp_legacy.localizedName)
        #expect(addr_dec_legacy.type == addr_comp_legacy.type)
        #expect(addr_comp_legacy.value == "1JjXGY5KEcbT35uAo6P9A7DebBn4DXnjdQ") // we ignore uncompressed addresses
        #expect(throws: (any Error).self) {
            try service.makeAddress(from: Keys.AddressesKeys.edKey)
        }
    }

    @Test
    func inavalidCurveGeneration_throwsError() throws {
        #expect(throws: (any Error).self) {
            try service.makeAddress(from: Keys.AddressesKeys.edKey)
        }
    }

    @Test
    func testnetAddressGeneration() throws {
        let service = BitcoinCashAddressService(networkParams: BitcoinCashTestNetworkParams())

        let addr_dec_default = try service.makeAddress(from: Keys.AddressesKeys.secpDecompressedKey, type: .default)
        let addr_comp_default = try service.makeAddress(from: Keys.AddressesKeys.secpCompressedKey, type: .default)

        #expect(addr_dec_default.value == addr_comp_default.value)
        #expect(addr_dec_default.localizedName == addr_comp_default.localizedName)
        #expect(addr_dec_default.type == addr_comp_default.type)
        #expect(addr_comp_default.value == "bchtest:dlpgfcqrnqvp33vsex0clktvae2pqjfxnyrlu7zk0g") // we ignore uncompressed addresses
    }

    @Test
    func testnetAddressGeneration_Legacy() throws {
        let service = BitcoinCashAddressService(networkParams: BitcoinCashTestNetworkParams())

        let addr_dec_legacy = try service.makeAddress(from: Keys.AddressesKeys.secpDecompressedKey, type: .legacy)
        let addr_comp_legacy = try service.makeAddress(from: Keys.AddressesKeys.secpCompressedKey, type: .legacy)

        #expect(addr_dec_legacy.value == addr_comp_legacy.value)
        #expect(addr_dec_legacy.localizedName == addr_comp_legacy.localizedName)
        #expect(addr_dec_legacy.type == addr_comp_legacy.type)
        #expect(addr_comp_legacy.value == "myFUZbAJ3e2hpCNnWfMWz2RyTBNm7vdnSQ") // we ignore uncompressed addresses
    }

    @Test(arguments: [
        "bitcoincash:qruxj7zq6yzpdx8dld0e9hfvt7u47zrw9gfr5hy0vh",
        "qruxj7zq6yzpdx8dld0e9hfvt7u47zrw9gfr5hy0vh",
        "bitcoincash:prm3srpqu4kmx00370m4wt5qr3cp7sekmcksezufmd",
        "1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2",
    ])
    func addressValidation_validAddresses(addressHex: String) {
        #expect(service.validate(addressHex))
    }
}
