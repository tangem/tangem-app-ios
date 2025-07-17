//
//  AlephiumAddressTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import Testing
@testable import BlockchainSdk

struct AlephiumAddressTests {
    private let addressService: AlephiumAddressService

    init() {
        addressService = AlephiumAddressService()
    }

    @Test
    func defaultAddressGeneration() throws {
        // given
        let addressService = AlephiumAddressService()
        let publicKeyData = Data(hexString: "0x025ad4a937b43f426d1bc2de5a5061c82c5218b2d0f52c132b3ddd0d6c07c4efca")
        let expectedAddress = "1HqAa1eHkqmXuSh7ECW6jF9ygZ2CMZYe1JthwcQ7NbgUe"

        // when
        let address = try addressService.makeAddress(from: publicKeyData)

        // then
        #expect(address.value == expectedAddress)
    }

    @Test
    func addressGeneration() throws {
        // given
        let expectedAddress = "12ZGzgQEpgQCWQrD8eyNihFXBF7QPGbWzSnGQSSUES98E"

        // when
        let compressedAddress = try addressService.makeAddress(from: Keys.AddressesKeys.secpCompressedKey, type: .default)
        let decompressedAddress = try addressService.makeAddress(from: Keys.AddressesKeys.secpDecompressedKey, type: .default)

        // then
        #expect(compressedAddress.value == expectedAddress)
        #expect(compressedAddress.value == decompressedAddress.value)
    }

    @Test
    func invalidCurveGeneration_throwsError() async throws {
        #expect(throws: (any Error).self) {
            try addressService.makeAddress(from: Keys.AddressesKeys.edKey)
        }
    }

    @Test(.serialized, arguments: [
        "12ZGzgQEpgQCWQrD8eyNihFXBF7QPGbWzSnGQSSUES98E",
        "1HqAa1eHkqmXuSh7ECW6jF9ygZ2CMZYe1JthwcQ7NbgUe",
    ])
    func addressValidation_validAddresses(address: String) throws {
        #expect(addressService.validate(address))
    }

    @Test(.serialized, arguments: [
        "0x00",
        "0x0",
        "1HqAa1eHkqmXuSh7ECW6jF9ygZ2CMZYe1JthwcQ7NsKSmsak",
        "1HqAa1eHkqmXuSh7ECW6jF9ygZ2CMZYe1J",
    ])
    func addressValidation_invalidAddresses(address: String) throws {
        #expect(!addressService.validate(address))
    }
}
