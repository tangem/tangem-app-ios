//
//  DynamicAddressesCustomDerivationCheckerTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
import TangemSdk
@testable import Tangem

@Suite("DynamicAddressesCustomDerivationChecker")
struct DynamicAddressesCustomDerivationCheckerTests {
    // MARK: - canAddCustomToken

    @Test("canAddCustomToken: allows adding on non-UTXO blockchain")
    func canAddCustomToken_allowsOnUnsupportedBlockchain() throws {
        let candidate = try makeItem(.ethereum(testnet: false), path: "m/44'/60'/0'")
        let existing = try makeItem(.bitcoin(testnet: false), path: "m/44'/0'/0'", mode: .xpub)

        let result = DynamicAddressesCustomDerivationChecker.canAddCustomToken(
            tokenItem: candidate,
            existingTokens: [existing]
        )

        #expect(result == true)
    }

    @Test("canAddCustomToken: allows when no existing tokens have dynamic addresses enabled")
    func canAddCustomToken_allowsWhenNoDynamicAddressesEnabled() throws {
        let candidate = try makeItem(.bitcoin(testnet: false), path: "m/44'/0'/0'")
        let existingOnSameAccount = try makeItem(.bitcoin(testnet: false), path: "m/44'/0'/0'", mode: .plain)

        let result = DynamicAddressesCustomDerivationChecker.canAddCustomToken(
            tokenItem: candidate,
            existingTokens: [existingOnSameAccount]
        )

        #expect(result == true)
    }

    @Test("canAddCustomToken: blocks when the same account has dynamic addresses enabled")
    func canAddCustomToken_blocksOnSameAccountWithDynamicAddressesEnabled() throws {
        let candidate = try makeItem(.bitcoin(testnet: false), path: "m/44'/0'/0'")
        let existing = try makeItem(.bitcoin(testnet: false), path: "m/44'/0'/0'", mode: .xpub)

        let result = DynamicAddressesCustomDerivationChecker.canAddCustomToken(
            tokenItem: candidate,
            existingTokens: [existing]
        )

        #expect(result == false)
    }

    @Test("canAddCustomToken: allows when dynamic addresses is enabled on a different account of the same blockchain")
    func canAddCustomToken_allowsOnDifferentAccount() throws {
        let candidate = try makeItem(.bitcoin(testnet: false), path: "m/44'/0'/0'")
        let existingOnOtherAccount = try makeItem(.bitcoin(testnet: false), path: "m/44'/0'/1'", mode: .xpub)

        let result = DynamicAddressesCustomDerivationChecker.canAddCustomToken(
            tokenItem: candidate,
            existingTokens: [existingOnOtherAccount]
        )

        #expect(result == true)
    }

    @Test("canAddCustomToken: allows when dynamic addresses is enabled on a different blockchain")
    func canAddCustomToken_allowsOnDifferentBlockchain() throws {
        let candidate = try makeItem(.bitcoin(testnet: false), path: "m/44'/0'/0'")
        let existingOnOtherBlockchain = try makeItem(.litecoin, path: "m/44'/2'/0'", mode: .xpub)

        let result = DynamicAddressesCustomDerivationChecker.canAddCustomToken(
            tokenItem: candidate,
            existingTokens: [existingOnOtherBlockchain]
        )

        #expect(result == true)
    }

    // MARK: - canEnableDynamicAddresses

    @Test("canEnableDynamicAddresses: allows on non-UTXO blockchain regardless of siblings")
    func canEnableDynamicAddresses_allowsOnUnsupportedBlockchain() throws {
        let candidate = try makeItem(.ethereum(testnet: false), path: "m/44'/60'/0'")
        let sibling = try makeItem(.ethereum(testnet: false), path: "m/44'/60'/0'", token: makeTestToken(contract: "eth-usdt"))

        let result = DynamicAddressesCustomDerivationChecker.canEnableDynamicAddresses(
            for: candidate,
            existingTokens: [sibling]
        )

        #expect(result == true)
    }

    @Test("canEnableDynamicAddresses: allows when there are no other tokens")
    func canEnableDynamicAddresses_allowsWithNoSiblings() throws {
        let candidate = try makeItem(.bitcoin(testnet: false), path: "m/44'/0'/0'")

        let result = DynamicAddressesCustomDerivationChecker.canEnableDynamicAddresses(
            for: candidate,
            existingTokens: []
        )

        #expect(result == true)
    }

    @Test("canEnableDynamicAddresses: ignores the candidate itself in the existing list")
    func canEnableDynamicAddresses_ignoresCandidateInExistingList() throws {
        let candidate = try makeItem(.bitcoin(testnet: false), path: "m/44'/0'/0'")

        let result = DynamicAddressesCustomDerivationChecker.canEnableDynamicAddresses(
            for: candidate,
            existingTokens: [candidate]
        )

        #expect(result == true)
    }

    @Test("canEnableDynamicAddresses: blocks when a sibling sits on the same blockchain and account")
    func canEnableDynamicAddresses_blocksWithSiblingOnSameAccount() throws {
        let network = try BlockchainNetwork(.bitcoin(testnet: false), derivationPath: DerivationPath(rawPath: "m/44'/0'/0'"))
        let candidate = TokenItem.blockchain(network)
        let sibling = TokenItem.token(makeTestToken(contract: "btc-test"), network)

        let result = DynamicAddressesCustomDerivationChecker.canEnableDynamicAddresses(
            for: candidate,
            existingTokens: [sibling]
        )

        #expect(result == false)
    }

    @Test("canEnableDynamicAddresses: allows when sibling sits on a different account of the same blockchain")
    func canEnableDynamicAddresses_allowsWithSiblingOnDifferentAccount() throws {
        let candidate = try makeItem(.bitcoin(testnet: false), path: "m/44'/0'/0'")
        let sibling = try makeItem(.bitcoin(testnet: false), path: "m/44'/0'/1'")

        let result = DynamicAddressesCustomDerivationChecker.canEnableDynamicAddresses(
            for: candidate,
            existingTokens: [sibling]
        )

        #expect(result == true)
    }

    @Test("canEnableDynamicAddresses: allows when sibling sits on a different blockchain")
    func canEnableDynamicAddresses_allowsWithSiblingOnDifferentBlockchain() throws {
        let candidate = try makeItem(.bitcoin(testnet: false), path: "m/44'/0'/0'")
        let sibling = try makeItem(.litecoin, path: "m/44'/2'/0'")

        let result = DynamicAddressesCustomDerivationChecker.canEnableDynamicAddresses(
            for: candidate,
            existingTokens: [sibling]
        )

        #expect(result == true)
    }
}

// MARK: - Helpers

private func makeItem(
    _ blockchain: Blockchain,
    path: String,
    mode: BlockchainNetwork.DerivationMode = .plain,
    token: Token? = nil
) throws -> TokenItem {
    let network = try BlockchainNetwork(
        blockchain,
        derivationPath: DerivationPath(rawPath: path),
        derivationMode: mode
    )
    if let token {
        return .token(token, network)
    }
    return .blockchain(network)
}

private func makeTestToken(contract: String) -> Token {
    Token(name: "Test", symbol: "TST", contractAddress: contract, decimalCount: 8)
}
