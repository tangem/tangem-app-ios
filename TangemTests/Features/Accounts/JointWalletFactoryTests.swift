//
//  JointWalletFactoryTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
@testable import Tangem

// MARK: - Tests

/// The wallet of a joint account lives at the address the account is given, not at the one its key derives.
@Suite("Tests for building the wallet of a joint account")
struct JointWalletFactoryTests {
    @Test("Without an address there is no wallet to build; once it arrives, the same factory builds the wallet there")
    func walletFollowsTheAddress() throws {
        let safeAddressProvider = JointAccountSafeAddressProviderStub()
        let sut = JointWalletFactory(defaultWalletFactory: DefaultWalletFactoryStub(), safeAddressProvider: safeAddressProvider)
        let blockchainNetwork = BlockchainNetwork(.ethereum(testnet: false), derivationPath: nil)

        let error = #expect(throws: AnyWalletFactoryError.self) {
            try sut.makeWallet(blockchainNetwork: blockchainNetwork, keys: [])
        }
        guard case .accountAddressUnavailable? = error else {
            Issue.record("Expected the address to be reported unavailable, got \(String(describing: error))")
            return
        }

        safeAddressProvider.send(Self.safeAddress)
        let wallet = try sut.makeWallet(blockchainNetwork: blockchainNetwork, keys: [])

        #expect(wallet.address == Self.safeAddress)
        #expect(wallet.publicKey == DefaultWalletFactoryStub.publicKey)
    }
}

// MARK: - Helpers

private extension JointWalletFactoryTests {
    static let safeAddress = "0x8f3a1C5E7B9D0246A8C0E2B4D6F8A0C2E4B6c21b"

    /// The wallet the member's own key derives, whose address the joint account's is meant to replace.
    struct DefaultWalletFactoryStub: AnyWalletFactory {
        static let publicKey = Wallet.PublicKey(seedKey: Data(repeating: 0x01, count: 33), derivationType: .none)

        func makeWallet(blockchainNetwork: BlockchainNetwork, keys: [KeyInfo]) throws -> Wallet {
            Wallet(
                blockchain: blockchainNetwork.blockchain,
                publicKey: Self.publicKey,
                addressesProvider: CommonAddressesProvider(defaultAddress: PlainAddress(value: "0xDerivedFromTheKey", type: .default))
            )
        }
    }
}
