//
//  ChiaAddressTests.swift
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

struct ChiaAddressTests {
    @Test
    func addressValidation() throws {
        // given
        let blockchain = Blockchain.chia(testnet: true)
        let addressService = ChiaAddressService(isTestnet: blockchain.isTestnet)
        let expectedAddress = "txch14gxuvfmw2xdxqnws5agt3ma483wktd2lrzwvpj3f6jvdgkmf5gtq8g3aw3"

        // when
        let address = try addressService.makeAddress(
            from: Data(hex: "b8f7dd239557ff8c49d338f89ac1a258a863fa52cd0a502e3aaae4b6738ba39ac8d982215aa3fa16bc5f8cb7e44b954d")
        ).value

        // then
        #expect(expectedAddress == address)

        #expect(throws: (any Error).self) {
            try addressService.makeAddress(from: Keys.AddressesKeys.secpCompressedKey)
        }

        #expect(throws: (any Error).self) {
            try addressService.makeAddress(from: Keys.AddressesKeys.edKey)
        }
    }

    @Test(arguments: [
        "txch14gxuvfmw2xdxqnws5agt3ma483wktd2lrzwvpj3f6jvdgkmf5gtq8g3aw3",
        "txch1rpu5dtkfkn48dv5dmpl00hd86t8jqvskswv8vlqz2nlucrrysxfscxm96k",
        "txch1lhfzlt7tz8whecqnnrha4kcxgfk9ct77j0aq0a844766fpjfv2rsp9wgas",
    ])
    func addressValidation_validAddresses(address: String) {
        let blockchain = Blockchain.chia(testnet: true)
        let addressService = ChiaAddressService(isTestnet: blockchain.isTestnet)
        #expect(addressService.validate(address))
    }

    @Test(arguments: [
        "txch14gxuvfmw2xdxqnws5agt3ma483wktd2lrzwvpj3f",
        "txch1rpu5dtkfkn48dv5dmpl00hd86t8jqvskswv8vlqz2nlucrrysxfscxm96667d233ms",
        "xch1lhfzlt7tz8whecqnnrha4kcxgfk9ct77j0aq0a844766fpjfv2rsp9wgas"
    ])
    func addressValidation_invalidAddresses(address: String) {
        let blockchain = Blockchain.chia(testnet: true)
        let addressService = ChiaAddressService(isTestnet: blockchain.isTestnet)
        #expect(!addressService.validate(address))
    }
}
