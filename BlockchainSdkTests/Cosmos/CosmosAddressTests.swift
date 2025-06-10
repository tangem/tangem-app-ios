//
//  CosmosAddressTests.swift
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
import enum WalletCore.CoinType

struct CosmosAddressTests {
    @Test
    func defaultAddressGeneration() throws {
        let addressService = WalletCoreAddressService(coin: .cosmos)

        let expectedAddress = "cosmos1c2zwqqucrqvvtyxfn78ajm8w2sgyjf5emztyek"

        let secpCompressedAddress = try addressService.makeAddress(from: Keys.AddressesKeys.secpCompressedKey).value
        let secpDecompressedAddress = try addressService.makeAddress(from: Keys.AddressesKeys.secpDecompressedKey).value

        #expect(expectedAddress == secpCompressedAddress)
        #expect(expectedAddress == secpDecompressedAddress)

        #expect(throws: (any Error).self) {
            try addressService.makeAddress(from: Keys.AddressesKeys.edKey)
        }
    }

    @Test(arguments: [
        "cosmos1hsk6jryyqjfhp5dhc55tc9jtckygx0eph6dd02",
        "cosmospub1addwnpepqftjsmkr7d7nx4tmhw4qqze8w39vjq364xt8etn45xqarlu3l2wu2n7pgrq",
        "cosmosvaloper1sxx9mszve0gaedz5ld7qdkjkfv8z992ax69k08",
        "cosmosvalconspub1zcjduepqjnnwe2jsywv0kfc97pz04zkm7tc9k2437cde2my3y5js9t7cw9mstfg3sa",
    ])
    func validAddresses(addressHex: String) {
        let walletCoreAddressValidator: AddressValidator = WalletCoreAddressService(coin: .cosmos, publicKeyType: CoinType.cosmos.publicKeyType)
        let addressValidator = AddressServiceFactory(blockchain: .cosmos(testnet: false)).makeAddressService()

        #expect(walletCoreAddressValidator.validate(addressHex))
        #expect(addressValidator.validate(addressHex))
    }

    @Test(arguments: [
        "cosmoz1hsk6jryyqjfhp5dhc55tc9jtckygx0eph6dd02",
        "osmo1mky69cn8ektwy0845vec9upsdphktxt0en97f5",
        "cosmosvaloper1sxx9mszve0gaedz5ld7qdkjkfv8z992ax69k03",
        "cosmosvalconspub1zcjduepqjnnwe2jsywv0kfc97pz04zkm7tc9k2437cde2my3y5js9t7cw9mstfg3sb",
    ])
    func invalidAddresses(addressHex: String) {
        let walletCoreAddressValidator: AddressValidator
        walletCoreAddressValidator = WalletCoreAddressService(coin: .cosmos, publicKeyType: CoinType.cosmos.publicKeyType)
        let addressValidator = AddressServiceFactory(blockchain: .cosmos(testnet: false)).makeAddressService()

        #expect(!walletCoreAddressValidator.validate(addressHex))
        #expect(!addressValidator.validate(addressHex))
    }
}
