//
//  ICPAddressTests.swift
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

struct ICPAddressTests {
    private let addressService = AddressServiceFactory(blockchain: .internetComputer).makeAddressService()

    @Test
    func addressGeneration() throws {
        // given
        let expectedAddress = "270b15681e87d9d878ddfcf1aae4c3174295f2182efa0e533e9585c7fb940bdc"

        // when
        let addressFromDecompressedKey = try addressService.makeAddress(from: Keys.AddressesKeys.secpDecompressedKey).value
        let addressFromCompressedKey = try addressService.makeAddress(from: Keys.AddressesKeys.secpCompressedKey).value

        // then
        #expect(expectedAddress == addressFromDecompressedKey)
        #expect(expectedAddress == addressFromCompressedKey)

        #expect(throws: (any Error).self) {
            try addressService.makeAddress(from: Keys.AddressesKeys.edKey)
        }
    }

    @Test
    func addressValidation() throws {
        #expect(addressService.validate("f7b1299849420e082bbdd9de92cb36e0645e7870513a6eb833d5449a88799699"))
    }
}
