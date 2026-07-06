//
//  GonkaAddressTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore
@testable import BlockchainSdk
import Testing

struct GonkaAddressTests {
    private let addressService = AddressServiceFactory(blockchain: .gonka(testnet: false)).makeAddressService()

    @Test
    func defaultAddressGeneration() throws {
        let expectedOutput = "gonka12rtn7e5lh6y6zftgc69gh7a0cny44089m8y0kr"

        let privateKey = PrivateKey(data: Data(hex: "2c179540bebbb6b862fb20fbb6713d3c9c5fc3464da61f0292735f74f35f8586"))!
        let publicKeyData = privateKey.getPublicKeySecp256k1(compressed: true).data
        let gonkaAddress = try addressService.makeAddress(from: publicKeyData).value

        #expect(gonkaAddress == expectedOutput)
    }

    @Test
    func makeInvalidAddress() throws {
        let privateKey = PrivateKey(data: Data(hex: "2c179540bebbb6b862fb20fbb6713d3c9c5fc3464da61f0292735f74f35f8586"))!
        let publicKeyData = privateKey.getPublicKeyEd25519().data

        #expect(throws: (any Error).self) {
            try addressService.makeAddress(from: publicKeyData)
        }
    }

    @Test(arguments: [
        "gonka1an29dzc6a8z4deqwy8e5jnux3gnazlfcmc45ua",
        "gonka1cscqkqptc5um3662nvmcv4rd44qn5mw0wkan2a",
        "gonka12rtn7e5lh6y6zftgc69gh7a0cny44089m8y0kr",
    ])
    func addressIsValid(addressHex: String) throws {
        #expect(addressService.validate(addressHex))
    }

    @Test(arguments: [
        "sei12rtn7e5lh6y6zftgc69gh7a0cny44089x7j8hq",
        "gonka",
        "gonka1234",
        "",
    ])
    func addressIsInvalid(addressHex: String) throws {
        #expect(!addressService.validate(addressHex))
    }
}
