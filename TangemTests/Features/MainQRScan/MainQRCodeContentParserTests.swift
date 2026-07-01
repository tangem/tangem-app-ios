//
//  MainQRCodeContentParserTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem
@testable import BlockchainSdk

@Suite("MainQRCodeContentParser")
struct MainQRCodeContentParserTests {
    private let parser = MainQRCodeContentParser()

    // MARK: - Unrecognized

    @Test("Empty or whitespace-only input is unrecognized", arguments: ["", "   ", "\n\t"])
    func emptyIsUnrecognized(_ input: String) {
        #expect(isUnrecognized(parser.parse(input)))
    }

    @Test(
        "Plain HTTP/HTTPS links are unrecognized",
        arguments: [
            "http://example.com",
            "https://tangem.com/foo",
            "HTTPS://UPPER.example",
        ]
    )
    func httpLinksAreUnrecognized(_ input: String) {
        #expect(isUnrecognized(parser.parse(input)))
    }

    // MARK: - Plain address

    @Test("A bare address without a scheme is treated as a plain address")
    func bareAddressIsPlain() {
        let address = "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62"

        guard case .plainAddress(let value) = parser.parse(address) else {
            Issue.record("Expected .plainAddress, got \(parser.parse(address))")
            return
        }

        #expect(value == address)
    }

    @Test("Arbitrary non-URI text is treated as a plain address")
    func arbitraryTextIsPlain() {
        guard case .plainAddress(let value) = parser.parse("just-some-text") else {
            Issue.record("Expected .plainAddress")
            return
        }

        #expect(value == "just-some-text")
    }

    // MARK: - Payment URI

    @Test("A Bitcoin URI is parsed as a payment request")
    func bitcoinPaymentURI() {
        let address = "bc1pw83rs5s75na2g7ec8yqgekr3ae209ye7ck2ftakjnh8tv3xzw8ls6wgt62"

        guard case .paymentURI(let request) = parser.parse("bitcoin:\(address)") else {
            Issue.record("Expected .paymentURI")
            return
        }

        #expect(request.blockchain == .bitcoin(testnet: false))
        #expect(request.destinationAddress == address)
    }

    @Test("An Ethereum EIP-681 coin URI is parsed as a payment request")
    func ethereumCoinURI() {
        let address = "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb"

        guard case .paymentURI(let request) = parser.parse("ethereum:\(address)") else {
            Issue.record("Expected .paymentURI")
            return
        }

        #expect(request.blockchain == .ethereum(testnet: false))
        #expect(request.destinationAddress == address)
        #expect(request.tokenContractAddress == nil)
    }

    @Test("An Ethereum EIP-681 token transfer URI captures the contract and recipient")
    func ethereumTokenTransferURI() {
        let contract = "0x89205A3A3b2A69De6Dbf7f01ED13B2108B2c43e7"
        let recipient = "0xc00f86ab93cd0bd3a60213583d0fe35aaa1ace23"

        guard case .paymentURI(let request) = parser.parse("ethereum:\(contract)/transfer?address=\(recipient)") else {
            Issue.record("Expected .paymentURI")
            return
        }

        #expect(request.blockchain == .ethereum(testnet: false))
        #expect(request.destinationAddress == recipient)
        #expect(request.tokenContractAddress == contract)
    }

    // MARK: - Helpers

    private func isUnrecognized(_ result: MainQRScanResult) -> Bool {
        if case .unrecognized = result {
            return true
        }

        return false
    }
}
