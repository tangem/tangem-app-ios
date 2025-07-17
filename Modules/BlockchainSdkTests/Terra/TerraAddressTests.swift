//
//  TerraAddressTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
@testable import BlockchainSdk
import Testing

struct TerraAddressTests {
    @Test(.serialized, arguments: [Blockchain.terraV1, .terraV2])
    func defaultAddressGeneration(blockchain: Blockchain) throws {
        let addressService = WalletCoreAddressService(blockchain: blockchain)
        let expectedAddress = "terra1c2zwqqucrqvvtyxfn78ajm8w2sgyjf5eax3ymk"

        let addressFromCompressedKey = try addressService.makeAddress(from: Keys.AddressesKeys.secpCompressedKey).value
        let addressFromDecompressedKey = try addressService.makeAddress(from: Keys.AddressesKeys.secpCompressedKey).value
        #expect(expectedAddress == addressFromCompressedKey)
        #expect(expectedAddress == addressFromDecompressedKey)

        #expect(throws: (any Error).self) {
            try addressService.makeAddress(from: Keys.AddressesKeys.edKey)
        }
    }

    @Test(.serialized, arguments: [
        "terra1hdp298kaz0eezpgl6scsykxljrje3667d233ms",
        "terravaloper1pdx498r0hrc2fj36sjhs8vuhrz9hd2cw0yhqtk",
    ])
    func addressValidation_validAddresses(address: String) throws {
        [Blockchain.terraV1, .terraV2].forEach {
            let addressService = WalletCoreAddressService(blockchain: $0)
            #expect(addressService.validate(address))
        }
    }

    @Test(.serialized, arguments: [
        "cosmos1hsk6jryyqjfhp5dhc55tc9jtckygx0eph6dd02",
    ])
    func addressValidation_invalidAddresses(address: String) throws {
        [Blockchain.terraV1, .terraV2].forEach {
            let addressService = WalletCoreAddressService(blockchain: $0)
            #expect(!addressService.validate(address))
        }
    }
}
