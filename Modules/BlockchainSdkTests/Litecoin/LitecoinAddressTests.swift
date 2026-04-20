//
//  LitecoinAddressTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Testing
@testable import BlockchainSdk

struct LitecoinAddressTests {
    private let addressesUtility = AddressServiceManagerUtility()
    private let addressService = AddressServiceFactory(blockchain: .litecoin).makeAddressService()

    @Test
    func addressGeneration() throws {
        let blockchain = Blockchain.litecoin

        #expect(throws: (any Error).self) {
            try addressService.makeAddress(from: Keys.AddressesKeys.edKey)
        }

        let bech32_dec = try addressService.makeAddress(from: Keys.AddressesKeys.secpDecompressedKey, type: .default)
        let bech32_comp = try addressService.makeAddress(from: Keys.AddressesKeys.secpCompressedKey, type: .default)

        #expect(bech32_dec.value == bech32_comp.value)
        #expect(bech32_dec.value == "ltc1qc2zwqqucrqvvtyxfn78ajm8w2sgyjf5efy0t9t") // [REDACTED_TODO_COMMENT]
        #expect(bech32_dec.localizedName == bech32_comp.localizedName)

        try #expect(addressesUtility.makeTrustWalletAddress(publicKey: Keys.AddressesKeys.secpDecompressedKey, for: blockchain) == bech32_dec.value)

        let leg_dec = try addressService.makeAddress(from: Keys.AddressesKeys.secpDecompressedKey, type: .legacy)
        let leg_comp = try addressService.makeAddress(from: Keys.AddressesKeys.secpCompressedKey, type: .legacy)
        #expect(leg_dec.localizedName == leg_comp.localizedName)
        #expect(leg_dec.value == "Lbg9FGXFbUTHhp6XXyrobK6ujBsu7UE7ww")
        #expect(leg_comp.value == "LcxUXkP9KGqWHtbKyENSS8HQoQ9LK8DQLX")
    }

    @Test
    func addressGeneration2() throws {
        let walletPublicKey = Data(hex: "041C1E7B3253E5C1E3519FB22894AD95285CE244D1D426A58D3178296A488FDC56699C85990B3EC09505253CB3C3FC7B712F1C6E953675922534B61D17408EAB39")
        let expectedAddress = "LWjJD6H1QrMmCQ5QhBKMqvPqMzwYpJPv2M"

        let address = try addressService.makeAddress(from: walletPublicKey, type: .legacy)
        #expect(address.value == expectedAddress)
    }

    @Test(arguments: [
        "LMbRCidgQLz1kNA77gnUpLuiv2UL6Bc4Q2",
        "ltc1q5wmm9vrz55war9c0rgw26tv9un5fxnn7slyjpy",
        "MPmoY6RX3Y3HFjGEnFxyuLPCQdjvHwMEny",
        "LWjJD6H1QrMmCQ5QhBKMqvPqMzwYpJPv2M",
    ])
    func addressValid(address: String) throws {
        #expect(addressService.validate(address))
    }

    @Test(arguments: [
        "1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2",
    ])
    func addressInvalid(address: String) throws {
        #expect(!addressService.validate(address))
    }
}
