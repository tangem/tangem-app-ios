//
//  WalletConnectAccountsWalletModelProviderTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
import BlockchainSdk
@testable import Tangem

@Suite("Tests for `AddressComparisonHelper` address matching")
struct WalletConnectAccountsWalletModelProviderTests {
    private let sut = CommonWalletConnectAccountsWalletModelProvider.AddressComparisonHelper()

    @Test("Matches legacy Bitcoin address")
    func matchesLegacyBitcoinAddress() {
        let legacyAddress = "1KWFv7SBZGMsneK2ZJ3D4aKcCzbvEyUbAA"
        let segwitAddress = "bc1qxzdqcmh6pknevm2ugtw94y50dwhsu3l0p5tg63"
        let blockchain = Blockchain.bitcoin(testnet: false)

        #expect(sut.matchesAnyAddress(
            addresses: [segwitAddress, legacyAddress],
            address: legacyAddress,
            blockchain: blockchain
        ))
    }

    @Test("Matches SegWit Bitcoin address across allowed case forms")
    func matchesSegWitBitcoinAddressAcrossAllowedCaseForms() {
        let legacyAddress = "1KWFv7SBZGMsneK2ZJ3D4aKcCzbvEyUbAA"
        let segwitAddress = "bc1qxzdqcmh6pknevm2ugtw94y50dwhsu3l0p5tg63"
        let blockchain = Blockchain.bitcoin(testnet: false)

        #expect(sut.matchesAnyAddress(
            addresses: [legacyAddress, segwitAddress],
            address: segwitAddress.uppercased(),
            blockchain: blockchain
        ))
    }
}
