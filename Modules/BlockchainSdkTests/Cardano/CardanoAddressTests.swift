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
    let extendedService = AddressServiceFactory(blockchain: .cardano(extended: true)).makeAddressService()

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

    @Test("Enterprise, base and Byron addresses pass both validators", arguments: Self.honestAddresses)
    func honestAddressIsAccepted(address: String) {
        #expect(service.validate(address))
        #expect(extendedService.validate(address))
    }

    @Test("A Shelley string whose bech32 HRP is not \"addr\" is rejected by both validators", arguments: Self.forgedShelleyAddresses)
    func forgedShelleyAddressIsRejected(address: String) {
        #expect(!service.validate(address))
        #expect(!extendedService.validate(address))
    }
}

// MARK: - Fixtures

private extension CardanoAddressTests {
    static let payeeEnterpriseAddress = "addr1vyq5f2ntspszzu77guh8kg4gkhzerws5t9jd6gg4d222yfsajkfw5"
    static let payeeBaseAddress = "addr1q90uh2eawrdc9vaemftgd50l28yrh9lqxtjjh4z6dnn0u7ggasexxdyyk9f05atygnjlccsjsggtc87hhqjna32fpv5qeq96ls"
    static let byronAddress = "Ae2tdPwUPEZAwboh4Qb8nzwQe6kmT5A3EmGKAKuS6Tcj8UkHy6BpQFnFnND"

    static let honestAddresses = [payeeEnterpriseAddress, payeeBaseAddress, byronAddress]

    static let forgedShelleyAddresses = [
        payeeEnterpriseAddress + "1vyn5mah4qzseuaxt5tj7sd5qf8rahy63ypzt3k4rvzvlzsghctmp7",
        "addr11vyn5mah4qzseuaxt5tj7sd5qf8rahy63ypzt3k4rvzvlzsggwzmd5",
        payeeEnterpriseAddress + "1vyn5mah4qzseuaxt5tj7sd5qf8rahy63ypzt3k4rvzvlzsgzymhyu",
        payeeEnterpriseAddress + "1w89res42a6qj0skt5hlmlyvvxzy6lh0wacnyzun9pz960ccpucf3j",
        String(payeeBaseAddress.prefix(66)) + "1vyn5mah4qzseuaxt5tj7sd5qf8rahy63ypzt3k4rvzvlzsg3rkhag",
    ]
}
