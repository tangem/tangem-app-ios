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

    @Test
    func defaultAddressGeneration() throws {
        let blockchain = Blockchain.dash(testnet: false)
        let addressService = BitcoinLegacyAddressService(networkParams: DashMainNetworkParams())

        let compressedExpectedAddress = "XtRN6njDCKp3C2VkeyhN1duSRXMkHPGLgH"
        let decompressedExpectedAddress = "Xs92pJsKUXRpbwzxDjBjApiwMK6JysNntG"

        // when
        let compressedKeyAddress = try addressService.makeAddress(from: Keys.AddressesKeys.secpCompressedKey)
        let decompressedKeyAddress = try addressService.makeAddress(from: Keys.AddressesKeys.secpDecompressedKey)

        // then
        #expect(compressedKeyAddress.value == compressedExpectedAddress)
        #expect(decompressedKeyAddress.value == decompressedExpectedAddress)

        let addressUtility = try addressesUtility.makeTrustWalletAddress(publicKey: Keys.AddressesKeys.secpCompressedKey, for: blockchain)
        #expect(addressUtility == compressedKeyAddress.value)
    }

    @Test
    func invalidCurveGeneration_throwsError() async throws {
        let addressService = BitcoinLegacyAddressService(networkParams: DashMainNetworkParams())
        #expect(throws: (any Error).self) {
            try addressService.makeAddress(from: Keys.AddressesKeys.edKey)
        }
    }

    @Test(.serialized, arguments: [
        "XwrhJMJKUpP21KShxqv6YcaTQZfiZXdREQ",
        "XdDGLNAAXF91Da58hYwHqQmFEWPGTh3L8p",
        "XuRzigQHyJfvw35e281h5HPBqJ8HZjF8M4",
    ])
    func addressValidation_validAddresses(address: String) throws {
        let addressService = BitcoinLegacyAddressService(networkParams: DashMainNetworkParams())
        #expect(addressService.validate(address))
    }

    @Test(.serialized, arguments: [
        "RJRyWwFs9wTFGZg3JbrVriFbNfCug5tDeC",
        "XuRzigQHyJfvw35e281h5HPBqJ8",
        "",
    ])
    func addressValidation_invalidAddresses(address: String) async throws {
        let addressService = BitcoinLegacyAddressService(networkParams: DashMainNetworkParams())
        #expect(!addressService.validate(address))
    }
}
