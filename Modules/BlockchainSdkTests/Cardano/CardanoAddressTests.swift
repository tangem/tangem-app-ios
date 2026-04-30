//
//  CardanoAddressTests.swift
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

struct CardanoAddressTests {
    let service = AddressServiceFactory(blockchain: .cardano(extended: false)).makeAddressService()

    @Test
    func byronAddressGeneration() throws {
        // when
        let addrs = try service.makeAddress(from: Keys.AddressesKeys.edKey, type: .legacy)

        // then
        #expect(addrs.localizedName == AddressType.legacy.defaultLocalizedName)
        #expect(addrs.value == "Ae2tdPwUPEZAwboh4Qb8nzwQe6kmT5A3EmGKAKuS6Tcj8UkHy6BpQFnFnND")
        #expect(throws: (any Error).self) {
            try service.makeAddress(from: Keys.AddressesKeys.secpCompressedKey)
        }
        #expect(throws: (any Error).self) {
            try service.makeAddress(from: Keys.AddressesKeys.secpDecompressedKey)
        }
    }

    @Test
    func shelleyAddressGeneration() throws {
        // when
        let addrs_shelley = try service.makeAddress(from: Keys.AddressesKeys.edKey, type: .default) // default is shelley
        let addrs_byron = try service.makeAddress(from: Keys.AddressesKeys.edKey, type: .legacy) // legacy is byron

        // then
        #expect(addrs_byron.localizedName == AddressType.legacy.defaultLocalizedName)
        #expect(addrs_byron.value == "Ae2tdPwUPEZAwboh4Qb8nzwQe6kmT5A3EmGKAKuS6Tcj8UkHy6BpQFnFnND")

        #expect(addrs_shelley.localizedName == AddressType.default.defaultLocalizedName)
        #expect(addrs_shelley.value == "addr1vyq5f2ntspszzu77guh8kg4gkhzerws5t9jd6gg4d222yfsajkfw5")

        #expect(throws: (any Error).self) {
            try service.makeAddress(from: Keys.AddressesKeys.secpCompressedKey)
        }
        #expect(throws: (any Error).self) {
            try service.makeAddress(from: Keys.AddressesKeys.secpDecompressedKey)
        }
    }
}
