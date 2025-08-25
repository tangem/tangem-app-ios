//
//  TronAddressTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemSdk
@testable import BlockchainSdk
import WalletCore
import Testing

struct TronAddressTests {
    private let addressesUtility = AddressServiceManagerUtility()
    private let blockchain = Blockchain.tron(testnet: false)

    @Test
    func defaultAddressGeneration() throws {
        // From https://developers.tron.network/docs/account
        let blockchain = Blockchain.tron(testnet: false)
        let service = AddressServiceFactory(blockchain: blockchain).makeAddressService()

        let publicKey = Data(hexString: "0404B604296010A55D40000B798EE8454ECCC1F8900E70B1ADF47C9887625D8BAE3866351A6FA0B5370623268410D33D345F63344121455849C9C28F9389ED9731")
        let address = try service.makeAddress(from: publicKey)
        #expect(address.value == "TDpBe64DqirkKWj6HWuR1pWgmnhw2wDacE")

        let compressedKeyAddress = try service.makeAddress(from: Keys.AddressesKeys.secpCompressedKey)
        #expect(compressedKeyAddress.value == "TL51KaL2EPoAnPLgnzdZndaTLEbd1P5UzV")

        let decompressedKeyAddress = try service.makeAddress(from: Keys.AddressesKeys.secpDecompressedKey)
        #expect(decompressedKeyAddress.value == "TL51KaL2EPoAnPLgnzdZndaTLEbd1P5UzV")

        #expect(service.validate("TJRyWwFs9wTFGZg3JbrVriFbNfCug5tDeC"))
        #expect(!service.validate("RJRyWwFs9wTFGZg3JbrVriFbNfCug5tDeC"))

        try #expect(addressesUtility.makeTrustWalletAddress(publicKey: publicKey, for: blockchain) == address.value)
    }

    @Test(arguments: [
        "TJRyWwFs9wTFGZg3JbrVriFbNfCug5tDeC",
    ])
    func validAddresses(addressHex: String) {
        let addressValidator = AddressServiceFactory(blockchain: blockchain).makeAddressService()
        #expect(addressValidator.validate(addressHex))
    }

    @Test(arguments: [
        "abc",
        "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed",
        "175tWpb8K1S7NmH4Zx6rewF9WQrcZv245W",
        "RJRyWwFs9wTFGZg3JbrVriFbNfCug5tDeC",
    ])
    func invalidAddresses(addressHex: String) {
        let addressValidator = AddressServiceFactory(blockchain: blockchain).makeAddressService()
        #expect(!addressValidator.validate(addressHex))
    }
}
