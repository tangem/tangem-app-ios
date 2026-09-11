//
//  SafeContractResponseDecoderTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
@testable import BlockchainSdk
import Testing

struct SafeContractResponseDecoderTests {
    @Test("An empty answer is an address without code")
    func emptyAnswerMeansNoCode() {
        #expect(!SafeContractResponseDecoder.hasCode("0x"))
        #expect(SafeContractResponseDecoder.hasCode("0x0000000000000000000000000000000000000000000000000000000000000007"))
    }

    @Test("The nonce and the threshold are single words")
    func nonceAndThresholdAreWords() throws {
        let word = "0x0000000000000000000000000000000000000000000000000000000000000007"

        #expect(try SafeContractResponseDecoder.nonce(from: word) == 7)
        #expect(try SafeContractResponseDecoder.threshold(from: word) == 7)
    }

    @Test("The owners are read off the dynamic array in the order the contract keeps them")
    func ownersAreReadOffTheDynamicArray() throws {
        let response = "0x"
            + "0000000000000000000000000000000000000000000000000000000000000020"
            + "0000000000000000000000000000000000000000000000000000000000000002"
            + "0000000000000000000000007e5fb2c1a9d3e5f70241c6b8a91cd9c1e7f45bdf"
            + "0000000000000000000000002b5ad9c1e7f40638b2c1a9d3e5f70241c6b8a91c"

        let owners = try SafeContractResponseDecoder.owners(from: response)

        #expect(owners == ["0x7e5fb2c1a9d3e5f70241c6b8a91cd9c1e7f45bdf", "0x2b5ad9c1e7f40638b2c1a9d3e5f70241c6b8a91c"])
    }

    @Test("An empty array is a Safe with no owners, not a failure")
    func emptyArrayIsRead() throws {
        let response = "0x"
            + "0000000000000000000000000000000000000000000000000000000000000020"
            + "0000000000000000000000000000000000000000000000000000000000000000"

        #expect(try SafeContractResponseDecoder.owners(from: response).isEmpty)
    }

    @Test("An array shorter than its length claims is refused")
    func truncatedArrayIsRefused() {
        let response = "0x"
            + "0000000000000000000000000000000000000000000000000000000000000020"
            + "0000000000000000000000000000000000000000000000000000000000000002"
            + "0000000000000000000000007e5fb2c1a9d3e5f70241c6b8a91cd9c1e7f45bdf"

        #expect(throws: SafeContractResponseDecoder.DecodingError.self) {
            try SafeContractResponseDecoder.owners(from: response)
        }
    }
}
