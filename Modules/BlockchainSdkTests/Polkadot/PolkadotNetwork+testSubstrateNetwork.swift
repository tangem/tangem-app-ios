//
//  PolkadotNetwork+testSubstrateNetwork.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
@testable import BlockchainSdk
import Testing

enum PolkadotNetworkTesting {
    static func testSubstrateNetwork(_ blockchain: Blockchain, publicKey: Data, expectedAddress: String) throws {
        let service = AddressServiceFactory(blockchain: blockchain).makeAddressService()
        let network = PolkadotNetwork(blockchain: blockchain)!

        let address = try! service.makeAddress(from: publicKey)
        let polkadotAddress = PolkadotAddress(string: expectedAddress, network: network)
        let addressFromString = try #require(polkadotAddress)

        #expect(addressFromString.bytes(raw: true) == publicKey)
        #expect(address.value == expectedAddress)
        #expect(addressFromString.bytes(raw: false) != publicKey)

        #expect(throws: (any Error).self) {
            try service.makeAddress(from: Keys.AddressesKeys.secpCompressedKey)
        }
        #expect(throws: (any Error).self) {
            try service.makeAddress(from: Keys.AddressesKeys.secpDecompressedKey)
        }
    }
}
