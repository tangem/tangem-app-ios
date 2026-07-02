//
//  MainQRScanRouteResolverTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem
@testable import BlockchainSdk

@Suite("MainQRScanRouteResolver")
struct MainQRScanRouteResolverTests {
    private let resolver = MainQRScanRouteResolver()
    private let ethAddress = "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb"
    private let ethCoin = TokenItem.blockchain(BlockchainNetwork(.ethereum(testnet: false), derivationPath: nil))

    @Test("Unrecognized content yields .showUnrecognized")
    func unrecognized() {
        let action = resolver.resolve(
            scannedCode: "http://example.com",
            availableBlockchains: [.ethereum(testnet: false)]
        )

        #expect(action == .showUnrecognized)
    }

    @Test("A payment URI with a matching token yields a payment action")
    func paymentWithMatch() {
        let action = resolver.resolve(
            scannedCode: "ethereum:\(ethAddress)",
            availableBlockchains: [.ethereum(testnet: false)],
            availableTokenItems: [ethCoin]
        )

        guard case .payment(let resolved) = action else {
            Issue.record("Expected .payment, got \(action)")
            return
        }

        #expect(resolved.request.destinationAddress == ethAddress)
        #expect(resolved.matchingTokenItems == [ethCoin])
    }

    @Test("A payment URI for an unavailable network yields .showNoSupportedTokens with payment context")
    func paymentNoSupportedTokens() {
        let action = resolver.resolve(
            scannedCode: "ethereum:\(ethAddress)",
            availableBlockchains: [.bitcoin(testnet: false)],
            availableTokenItems: []
        )

        guard case .showNoSupportedTokens(let context) = action else {
            Issue.record("Expected .showNoSupportedTokens, got \(action)")
            return
        }

        #expect(context?.networkId == Blockchain.ethereum(testnet: false).networkId)
    }

    @Test("A plain address valid for an available network yields an address action")
    func addressAction() {
        let action = resolver.resolve(
            scannedCode: ethAddress,
            availableBlockchains: [.ethereum(testnet: false)]
        )

        guard case .address(let request) = action else {
            Issue.record("Expected .address, got \(action)")
            return
        }

        #expect(request.destinationAddress == ethAddress)
        #expect(request.matchingBlockchains.contains(.ethereum(testnet: false)))
    }

    @Test("A globally valid address with no available networks yields .showNoSupportedTokens")
    func addressGloballyValidNoAvailable() {
        let action = resolver.resolve(scannedCode: ethAddress, availableBlockchains: [])

        #expect(action == .showNoSupportedTokens())
    }
}
