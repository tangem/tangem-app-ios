//
//  RavencoinAddressTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import enum WalletCore.CoinType
@testable import BlockchainSdk

struct RavencoinAddressTests {
    @Test
    func defaultAddressGeneration() throws {
        let addressService = AddressServiceFactory(blockchain: .ravencoin(testnet: false)).makeAddressService()

        let compAddress = try addressService.makeAddress(from: Keys.AddressesKeys.secpCompressedKey)
        let expectedCompAddress = "RT1iM3xbqSQ276GNGGNGFdYrMTEeq4hXRH"
        #expect(compAddress.value == expectedCompAddress)

        let decompAddress = try addressService.makeAddress(from: Keys.AddressesKeys.secpDecompressedKey)
        let expectedDecompAddress = "RRjP4a6i7e1oX1mZq1rdQpNMHEyDdSQVNi"
        #expect(decompAddress.value == expectedDecompAddress)

        #expect(addressService.validate(compAddress.value))
        #expect(addressService.validate(decompAddress.value))
    }

    @Test
    func inavalidCurveGeneration_throwsError() throws {
        let addressService = AddressServiceFactory(blockchain: .ravencoin(testnet: false)).makeAddressService()
        #expect(throws: (any Error).self) {
            try addressService.makeAddress(from: Keys.AddressesKeys.edKey)
        }
    }

    @Test(arguments: [
        "RT1iM3xbqSQ276GNGGNGFdYrMTEeq4hXRH",
        "RRjP4a6i7e1oX1mZq1rdQpNMHEyDdSQVNi",
    ])
    func addressValidation_validAddresses(addressHex: String) {
        let addressValidator = AddressServiceFactory(blockchain: .ravencoin(testnet: false)).makeAddressService()
        #expect(addressValidator.validate(addressHex))
    }

    @Test(arguments: [
        "QT1iM3xbqSQ276GNGGNGFdYrMTEeq4hXRH",
    ])
    func addressValidation_invalidAddresses(addressHex: String) {
        let addressValidator = AddressServiceFactory(blockchain: .ravencoin(testnet: false)).makeAddressService()
        #expect(!addressValidator.validate(addressHex))
    }
}
