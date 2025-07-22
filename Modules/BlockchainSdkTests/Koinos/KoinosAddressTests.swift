//
//  KoinosTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Testing
@testable import BlockchainSdk

struct KoinosAddressTests {
    private let addressService = AddressServiceFactory(blockchain: .koinos(testnet: false)).makeAddressService()

    @Test(arguments: [
        ("03B2D98CF41E82D9B99842A1D05860A1B06532015138F9067239706E06EE38E621", "1AYz8RCnoafLnifMjJbgNb2aeW5CbZj8Tp"),
        ("03607ffd808bdeab4dca2605854b2ab58ed18caf9034b6f0ad38a7fab065b6a997", "18KSv997KjmdraZvdjfvdy6dr3nFejLrV4"),
        ("030eeba48e9e8afb81322ba5ae1c79f960e3bca42534e9c7581b8b11273e46afd6", "1EcwHZbYn8L6C46fFyDcNNqPHzHpWu91QU"),
        ("03c4beb040a7867631c6570a3204fd3cfb9039dfddd3ccab8bed3adf3c5604e8d9", "18zebc8669iQXQJXeweY7WpTkV7KXw1px9"),
        ("03a5ce110ac3aeb610d6dcc565257af6efc43fef0801ffc2e7d37fd69befa6b4e3", "1P6uLkKezNTSDC3M3eiyoXSKibXpVwcmqc"),
    ])
    func makeAddress(pubKeyHex: String, expectedAddress: String) throws {
        let publicKey = Data(hex: pubKeyHex)
        let address = try addressService.makeAddress(from: publicKey).value
        #expect(address == expectedAddress)
    }

    @Test(arguments: [
        "1AYz8RCnoafLnifMjJbgNb2aeW5CbZj8Tp",
        "18KSv997KjmdraZvdjfvdy6dr3nFejLrV4",
        "1EcwHZbYn8L6C46fFyDcNNqPHzHpWu91QU",
        "18zebc8669iQXQJXeweY7WpTkV7KXw1px9",
        "1P6uLkKezNTSDC3M3eiyoXSKibXpVwcmqc",
    ])
    func validateCorrectAddress(address: String) {
        #expect(addressService.validate(address))
    }

    @Test(arguments: [
        "1AYz8RCnoafLnifMjJbgNb2aeW5CbZj8T",
        "18KSv997KjmdraZvdjfvdy6dr3nFejLrV",
        "1EcwHZbYn8L6C46fFyDcNNqPHzHpWu91Q",
        "18zebc8669iQXQJXeweY7WpTkV7KXw1px",
        "1P6uLkKezNTSDC3M3eiyoXSKibXpVwcmq",
    ])
    func validateIncorrectAddress(address: String) {
        #expect(!addressService.validate(address))
    }

    @Test(arguments: [
        "9FE5BB2CC7D83C1DA10845AFD8A34B141FD8FD72500B95B1547E12B9BB8AAC3D",
        "EC55E8D3F6B9C28F37B4CFA1A87896FB10ADAD42F0FC42FA8827D58032EF0E2E",
        "7C40243D15B7343A42DB8B9D12A9B676FB28B5F5DA9B8B5CC153ED2A16222C66",
        "05A297C37A0F287E937F4B9E1F451027DD118792B75E5B930B9B20A3AD7AFA94",
        "A9FA6D0866C3B3D8F5F2B9F8D8D45C6E81B8729A93E9E2423BBAB732FA1ED9AC",
    ])
    func edError(hexKey: String) {
        let edKey = Data(hex: hexKey)

        #expect(throws: (any Error).self) {
            try addressService.makeAddress(from: edKey)
        }
    }
}
