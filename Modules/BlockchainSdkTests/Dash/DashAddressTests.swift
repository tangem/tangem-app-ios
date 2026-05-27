//
//  DashAddressTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
@testable import BlockchainSdk
import Testing

struct DashAddressTests {
    private let addressesUtility = AddressServiceManagerUtility()
    private let addressService = AddressServiceFactory(blockchain: .dash(testnet: false)).makeAddressService()

    @Test
    func defaultAddressGeneration() throws {
        let compressedExpectedAddress = "XtRN6njDCKp3C2VkeyhN1duSRXMkHPGLgH"
        let decompressedExpectedAddress = "Xs92pJsKUXRpbwzxDjBjApiwMK6JysNntG"

        // when
        let compressedKeyAddress = try addressService.makeAddress(from: Keys.AddressesKeys.secpCompressedKey)
        let decompressedKeyAddress = try addressService.makeAddress(from: Keys.AddressesKeys.secpDecompressedKey)

        // then
        #expect(compressedKeyAddress.value == compressedExpectedAddress)
        #expect(decompressedKeyAddress.value == decompressedExpectedAddress)

        let addressUtility = try addressesUtility.makeTrustWalletAddress(publicKey: Keys.AddressesKeys.secpCompressedKey, for: .dash(testnet: false))
        #expect(addressUtility == compressedKeyAddress.value)
    }

    @Test
    func invalidCurveGeneration_throwsError() async throws {
        #expect(throws: (any Error).self) {
            try addressService.makeAddress(from: Keys.AddressesKeys.edKey)
        }
    }

    @Test(arguments: [
        "XwrhJMJKUpP21KShxqv6YcaTQZfiZXdREQ",
        "XdDGLNAAXF91Da58hYwHqQmFEWPGTh3L8p",
        "XuRzigQHyJfvw35e281h5HPBqJ8HZjF8M4",
    ])
    func addressValidation_validAddresses(address: String) throws {
        #expect(addressService.validate(address))
    }

    @Test(arguments: [
        "RJRyWwFs9wTFGZg3JbrVriFbNfCug5tDeC",
        "XuRzigQHyJfvw35e281h5HPBqJ8",
        "",
    ])
    func addressValidation_invalidAddresses(address: String) async throws {
        #expect(!addressService.validate(address))
    }
}
