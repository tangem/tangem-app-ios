//
//  SeiAddressTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore
@testable import BlockchainSdk
import Testing

struct SeiAddressTests {
    private let addressService = AddressServiceFactory(blockchain: .sei(testnet: true)).makeAddressService()

    @Test
    func defaultAddressGeneration() throws {
        let expectedOutput = "sei12rtn7e5lh6y6zftgc69gh7a0cny44089x7j8hq"

        let privateKey = PrivateKey(data: Data(hex: "2c179540bebbb6b862fb20fbb6713d3c9c5fc3464da61f0292735f74f35f8586"))!
        let publicKeyData = privateKey.getPublicKeySecp256k1(compressed: true).data
        let seiAddress = try addressService.makeAddress(from: publicKeyData).value

        #expect(seiAddress == expectedOutput)
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
        "sei142j9u5eaduzd7faumygud6ruhdwme98qagm0sj",
        "sei123mjxmap5j26x7ve8qes7gpm6uwah5lvxdpfs9",
        "sei1v4mx6hmrda5kucnpwdjsqqqqqqqqqqpqs3kax2",
    ])
    func addressIsValid(addressHex: String) throws {
        #expect(addressService.validate(addressHex))
    }

    @Test(arguments: [
        "kei142j9u5eaduzd7faumygud6ruhdwme98qagm0sj",
        "sei",
        "sei1234",
        "",
    ])
    func addressIsInvalid(addressHex: String) throws {
        #expect(!addressService.validate(addressHex))
    }
}
