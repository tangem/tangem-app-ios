//
//  DogecoinAddressTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
@testable import BlockchainSdk
import Testing

struct DogecoinAddressTests {
    private let addressesUtility = AddressServiceManagerUtility()
    let service = AddressServiceFactory(blockchain: .dogecoin).makeAddressService()

    @Test
    func defaultAddressGeneration() throws {
        let blockchain = Blockchain.dogecoin

        let addr_dec = try service.makeAddress(from: Keys.AddressesKeys.secpDecompressedKey)
        let addr_comp = try service.makeAddress(from: Keys.AddressesKeys.secpCompressedKey)

        #expect(addr_dec.value == "DMbHXKA4pE7Wz1ay6Rs4s4CkQ7EvKG3DqY")
        #expect(addr_dec.localizedName == addr_comp.localizedName)
        #expect(addr_dec.type == addr_comp.type)
        #expect(addr_comp.value == "DNscoo1xY2Vja65mXgNhhsPFUKWMa7NLEb")

        try #expect(addressesUtility.makeTrustWalletAddress(publicKey: Keys.AddressesKeys.secpDecompressedKey, for: blockchain) == addr_comp.value)
    }

    @Test
    func inavalidCurveGeneration_throwsError() async throws {
        #expect(throws: (any Error).self) {
            try service.makeAddress(from: Keys.AddressesKeys.edKey)
        }
    }

    @Test(arguments: [
        "DDWSSN4qy1ccJ1CYgaB6HGs4Euknqb476q",
        "D6H6nVsCmsodv7SLQd1KpfsmkUKmhXhP3g",
        "DCGx73ispbchmXfNczfp9TtWfKtzgzgp8N",
    ])
    func addressValidation_validAddresses(address: String) throws {
        #expect(service.validate(address))
    }

    @Test(arguments: [
        "DCGx73ispbchmXfNczfp9TtWfKtzgzgp",
        "CCGx73ispbchmXfNczfp9TtWfKtzgzgp8N",
        "",
    ])
    func addressValidation_invalidAddresses(address: String) throws {
        #expect(!service.validate(address))
    }
}
