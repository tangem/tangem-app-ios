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
    // MARK: - canAddCustomToken: blocking cases

    @Test("canAddCustomToken: blocks when custom receive address would clash with XPUB-derived address")
    func canAddCustomToken_blocksWhenCustomReceiveCollides() throws {
        // Given
        let candidate = try makeItem(.bitcoin(testnet: false), path: "m/84'/0'/0'/0/1")
        let existing = try makeItem(.bitcoin(testnet: false), path: "m/84'/0'/0'/0/0", settings: .dynamicAddresses)

        // When
        let result = DynamicAddressesCustomDerivationChecker.canAddCustomToken(
            tokenItem: candidate,
            existingTokens: [existing]
        )

        // Then
        #expect(!result)
    }

    @Test("canAddCustomToken: blocks when custom token sits on the change branch of an XPUB scope")
    func canAddCustomToken_blocksWhenCustomChangeCollides() throws {
        // Given
        let candidate = try makeItem(.bitcoin(testnet: false), path: "m/84'/0'/0'/1/0")
        let existing = try makeItem(.bitcoin(testnet: false), path: "m/84'/0'/0'/0/0", settings: .dynamicAddresses)

        // When
        let result = DynamicAddressesCustomDerivationChecker.canAddCustomToken(
            tokenItem: candidate,
            existingTokens: [existing]
        )

        // Then
        #expect(!result)
    }

    @Test("canAddCustomToken: blocks when paths are identical and existing has Dynamic Addresses enabled")
    func canAddCustomToken_blocksOnIdenticalPath() throws {
        // Given
        let candidate = try makeItem(.bitcoin(testnet: false), path: "m/84'/0'/0'/0/0")
        let existing = try makeItem(.bitcoin(testnet: false), path: "m/84'/0'/0'/0/0", settings: .dynamicAddresses)

        // When
        let result = DynamicAddressesCustomDerivationChecker.canAddCustomToken(
            tokenItem: candidate,
            existingTokens: [existing]
        )

        // Then
        #expect(!result)
    }

    @Test("canAddCustomToken: blocks when one of multiple existing tokens collides")
    func canAddCustomToken_blocksWhenAnyExistingCollides() throws {
        // Given
        let candidate = try makeItem(.bitcoin(testnet: false), path: "m/84'/0'/0'/0/1")
        let nonColliding = try makeItem(.bitcoin(testnet: false), path: "m/84'/0'/1'/0/0", settings: .dynamicAddresses)
        let colliding = try makeItem(.bitcoin(testnet: false), path: "m/84'/0'/0'/0/0", settings: .dynamicAddresses)

        // When
        let result = DynamicAddressesCustomDerivationChecker.canAddCustomToken(
            tokenItem: candidate,
            existingTokens: [nonColliding, colliding]
        )

        // Then
        #expect(!result)
    }

    // MARK: - canAddCustomToken: allowing cases

    @Test("canAddCustomToken: allows on a different account of the same blockchain")
    func canAddCustomToken_allowsOnDifferentAccount() throws {
        // Given
        let candidate = try makeItem(.bitcoin(testnet: false), path: "m/84'/0'/1'/0/0")
        let existing = try makeItem(.bitcoin(testnet: false), path: "m/84'/0'/0'/0/0", settings: .dynamicAddresses)

        // When
        let result = DynamicAddressesCustomDerivationChecker.canAddCustomToken(
            tokenItem: candidate,
            existingTokens: [existing]
        )

        // Then
        #expect(result)
    }

    @Test("canAddCustomToken: allows when purpose differs")
    func canAddCustomToken_allowsOnDifferentPurpose() throws {
        // Given
        let candidate = try makeItem(.bitcoin(testnet: false), path: "m/49'/0'/0'/0/0")
        let existing = try makeItem(.bitcoin(testnet: false), path: "m/84'/0'/0'/0/0", settings: .dynamicAddresses)

        // When
        let result = DynamicAddressesCustomDerivationChecker.canAddCustomToken(
            tokenItem: candidate,
            existingTokens: [existing]
        )

        // Then
        #expect(result)
    }

    @Test("canAddCustomToken: allows when coin_type differs")
    func canAddCustomToken_allowsOnDifferentCoinType() throws {
        // Given
        let candidate = try makeItem(.bitcoin(testnet: false), path: "m/84'/1'/0'/0/0")
        let existing = try makeItem(.bitcoin(testnet: false), path: "m/84'/0'/0'/0/0", settings: .dynamicAddresses)

        // When
        let result = DynamicAddressesCustomDerivationChecker.canAddCustomToken(
            tokenItem: candidate,
            existingTokens: [existing]
        )

        // Then
        #expect(result)
    }

    @Test("canAddCustomToken: allows when existing token does not have Dynamic Addresses enabled")
    func canAddCustomToken_allowsWhenExistingHasDynamicAddressesDisabled() throws {
        // Given
        let candidate = try makeItem(.bitcoin(testnet: false), path: "m/84'/0'/0'/0/0")
        let existing = try makeItem(.bitcoin(testnet: false), path: "m/84'/0'/0'/0/0")

        // When
        let result = DynamicAddressesCustomDerivationChecker.canAddCustomToken(
            tokenItem: candidate,
            existingTokens: [existing]
        )

        // Then
        #expect(result)
    }

    @Test("canAddCustomToken: allows when existing token is on a different blockchain")
    func canAddCustomToken_allowsOnDifferentBlockchain() throws {
        // Given
        let candidate = try makeItem(.bitcoin(testnet: false), path: "m/84'/0'/0'/0/0")
        let existing = try makeItem(.litecoin, path: "m/84'/2'/0'/0/0", settings: .dynamicAddresses)

        // When
        let result = DynamicAddressesCustomDerivationChecker.canAddCustomToken(
            tokenItem: candidate,
            existingTokens: [existing]
        )

        // Then
        #expect(result)
    }

    @Test("canAddCustomToken: allows when candidate blockchain does not support Dynamic Addresses")
    func canAddCustomToken_allowsOnUnsupportedBlockchain() throws {
        // Given
        let candidate = try makeItem(.ethereum(testnet: false), path: "m/44'/60'/0'/0/0")
        let existing = try makeItem(.bitcoin(testnet: false), path: "m/84'/0'/0'/0/0", settings: .dynamicAddresses)

        // When
        let result = DynamicAddressesCustomDerivationChecker.canAddCustomToken(
            tokenItem: candidate,
            existingTokens: [existing]
        )

        // Then
        #expect(result)
    }

    @Test("canAddCustomToken: allows when candidate path has fewer than 5 nodes")
    func canAddCustomToken_allowsWhenCandidatePathIsShort() throws {
        // Given
        let candidate = try makeItem(.bitcoin(testnet: false), path: "m/84'/0'/0'")
        let existing = try makeItem(.bitcoin(testnet: false), path: "m/84'/0'/0'/0/0", settings: .dynamicAddresses)

        // When
        let result = DynamicAddressesCustomDerivationChecker.canAddCustomToken(
            tokenItem: candidate,
            existingTokens: [existing]
        )

        // Then
        #expect(result)
    }

    @Test("canAddCustomToken: allows when candidate path stops at the change level (4 nodes)")
    func canAddCustomToken_allowsWhenCandidatePathHasFourNodes() throws {
        // Given
        let candidate = try makeItem(.bitcoin(testnet: false), path: "m/84'/0'/0'/0")
        let existing = try makeItem(.bitcoin(testnet: false), path: "m/84'/0'/0'/0/0", settings: .dynamicAddresses)

        // When
        let result = DynamicAddressesCustomDerivationChecker.canAddCustomToken(
            tokenItem: candidate,
            existingTokens: [existing]
        )

        // Then
        #expect(result)
    }

    @Test("canAddCustomToken: allows when candidate path has more than 5 nodes")
    func canAddCustomToken_allowsWhenCandidatePathIsLong() throws {
        // Given
        let candidate = try makeItem(.bitcoin(testnet: false), path: "m/84'/0'/0'/0/0/0")
        let existing = try makeItem(.bitcoin(testnet: false), path: "m/84'/0'/0'/0/0", settings: .dynamicAddresses)

        // When
        let result = DynamicAddressesCustomDerivationChecker.canAddCustomToken(
            tokenItem: candidate,
            existingTokens: [existing]
        )

        // Then
        #expect(result)
    }

    @Test("canAddCustomToken: allows when existing path has fewer than 5 nodes")
    func canAddCustomToken_allowsWhenExistingPathIsShort() throws {
        // Given
        let candidate = try makeItem(.bitcoin(testnet: false), path: "m/84'/0'/0'/0/0")
        let existing = try makeItem(.bitcoin(testnet: false), path: "m/84'/0'/0'", settings: .dynamicAddresses)

        // When
        let result = DynamicAddressesCustomDerivationChecker.canAddCustomToken(
            tokenItem: candidate,
            existingTokens: [existing]
        )

        // Then
        #expect(result)
    }

    @Test("canAddCustomToken: allows when there are no existing tokens")
    func canAddCustomToken_allowsWithEmptyList() throws {
        // Given
        let candidate = try makeItem(.bitcoin(testnet: false), path: "m/84'/0'/0'/0/0")

        // When
        let result = DynamicAddressesCustomDerivationChecker.canAddCustomToken(
            tokenItem: candidate,
            existingTokens: []
        )

        // Then
        #expect(result)
    }

    @Test("canAddCustomToken: allows when candidate derivation path is nil")
    func canAddCustomToken_allowsWhenCandidatePathIsNil() throws {
        // Given
        let candidate = makeItem(.bitcoin(testnet: false), derivationPath: nil)
        let existing = try makeItem(.bitcoin(testnet: false), path: "m/84'/0'/0'/0/0", settings: .dynamicAddresses)

        // When
        let result = DynamicAddressesCustomDerivationChecker.canAddCustomToken(
            tokenItem: candidate,
            existingTokens: [existing]
        )

        // Then
        #expect(result)
    }

    @Test("canAddCustomToken: allows when an existing token's derivation path is nil")
    func canAddCustomToken_allowsWhenExistingPathIsNil() throws {
        // Given
        let candidate = try makeItem(.bitcoin(testnet: false), path: "m/84'/0'/0'/0/0")
        let existing = makeItem(.bitcoin(testnet: false), derivationPath: nil, settings: .dynamicAddresses)

        // When
        let result = DynamicAddressesCustomDerivationChecker.canAddCustomToken(
            tokenItem: candidate,
            existingTokens: [existing]
        )

        // Then
        #expect(result)
    }

    // MARK: - canEnableDynamicAddresses: blocking cases

    @Test("canEnableDynamicAddresses: blocks when sibling custom token sits in the would-be receive scope")
    func canEnableDynamicAddresses_blocksWhenSiblingReceiveCollides() throws {
        // Given
        let candidate = try makeItem(.bitcoin(testnet: false), path: "m/84'/0'/0'/0/0")
        let sibling = try makeItem(.bitcoin(testnet: false), path: "m/84'/0'/0'/0/5")

        // When
        let result = DynamicAddressesCustomDerivationChecker.canEnableDynamicAddresses(
            for: candidate,
            existingTokens: [sibling]
        )

        // Then
        #expect(!result)
    }

    @Test("canEnableDynamicAddresses: blocks when sibling sits on the change branch of the would-be XPUB scope")
    func canEnableDynamicAddresses_blocksWhenSiblingChangeCollides() throws {
        // Given
        let candidate = try makeItem(.bitcoin(testnet: false), path: "m/84'/0'/0'/0/0")
        let sibling = try makeItem(.bitcoin(testnet: false), path: "m/84'/0'/0'/1/0")

        // When
        let result = DynamicAddressesCustomDerivationChecker.canEnableDynamicAddresses(
            for: candidate,
            existingTokens: [sibling]
        )

        // Then
        #expect(!result)
    }

    // MARK: - canEnableDynamicAddresses: allowing cases

    @Test("canEnableDynamicAddresses: allows when sibling sits on a different account of the same blockchain")
    func canEnableDynamicAddresses_allowsWithSiblingOnDifferentAccount() throws {
        // Given
        let candidate = try makeItem(.bitcoin(testnet: false), path: "m/84'/0'/0'/0/0")
        let sibling = try makeItem(.bitcoin(testnet: false), path: "m/84'/0'/1'/0/0")

        // When
        let result = DynamicAddressesCustomDerivationChecker.canEnableDynamicAddresses(
            for: candidate,
            existingTokens: [sibling]
        )

        // Then
        #expect(result)
    }

    @Test("canEnableDynamicAddresses: allows when sibling sits on a different blockchain")
    func canEnableDynamicAddresses_allowsWithSiblingOnDifferentBlockchain() throws {
        // Given
        let candidate = try makeItem(.bitcoin(testnet: false), path: "m/84'/0'/0'/0/0")
        let sibling = try makeItem(.litecoin, path: "m/84'/2'/0'/0/0")

        // When
        let result = DynamicAddressesCustomDerivationChecker.canEnableDynamicAddresses(
            for: candidate,
            existingTokens: [sibling]
        )

        // Then
        #expect(result)
    }

    @Test("canEnableDynamicAddresses: allows when only the candidate is in the existing list")
    func canEnableDynamicAddresses_ignoresCandidateInExistingList() throws {
        // Given
        let candidate = try makeItem(.bitcoin(testnet: false), path: "m/84'/0'/0'/0/0")

        // When
        let result = DynamicAddressesCustomDerivationChecker.canEnableDynamicAddresses(
            for: candidate,
            existingTokens: [candidate]
        )

        // Then
        #expect(result)
    }

    @Test("canEnableDynamicAddresses: allows when candidate blockchain does not support Dynamic Addresses")
    func canEnableDynamicAddresses_allowsOnUnsupportedBlockchain() throws {
        // Given
        let candidate = try makeItem(.ethereum(testnet: false), path: "m/44'/60'/0'/0/0")
        let sibling = try makeItem(.ethereum(testnet: false), path: "m/44'/60'/0'/0/0", token: makeTestToken(contract: "eth-usdt"))

        // When
        let result = DynamicAddressesCustomDerivationChecker.canEnableDynamicAddresses(
            for: candidate,
            existingTokens: [sibling]
        )

        // Then
        #expect(result)
    }

    @Test("canEnableDynamicAddresses: allows when sibling path has fewer than 5 nodes")
    func canEnableDynamicAddresses_allowsWhenSiblingPathIsShort() throws {
        // Given
        let candidate = try makeItem(.bitcoin(testnet: false), path: "m/84'/0'/0'/0/0")
        let sibling = try makeItem(.bitcoin(testnet: false), path: "m/84'/0'/0'")

        // When
        let result = DynamicAddressesCustomDerivationChecker.canEnableDynamicAddresses(
            for: candidate,
            existingTokens: [sibling]
        )

        // Then
        #expect(result)
    }

    @Test("canEnableDynamicAddresses: allows when sibling path stops at the change level (4 nodes)")
    func canEnableDynamicAddresses_allowsWhenSiblingPathHasFourNodes() throws {
        // Given
        let candidate = try makeItem(.bitcoin(testnet: false), path: "m/84'/0'/0'/0/0")
        let sibling = try makeItem(.bitcoin(testnet: false), path: "m/84'/0'/0'/0")

        // When
        let result = DynamicAddressesCustomDerivationChecker.canEnableDynamicAddresses(
            for: candidate,
            existingTokens: [sibling]
        )

        // Then
        #expect(result)
    }

    @Test("canEnableDynamicAddresses: allows when sibling path has more than 5 nodes")
    func canEnableDynamicAddresses_allowsWhenSiblingPathIsLong() throws {
        // Given
        let candidate = try makeItem(.bitcoin(testnet: false), path: "m/84'/0'/0'/0/0")
        let sibling = try makeItem(.bitcoin(testnet: false), path: "m/84'/0'/0'/0/0/0")

        // When
        let result = DynamicAddressesCustomDerivationChecker.canEnableDynamicAddresses(
            for: candidate,
            existingTokens: [sibling]
        )

        // Then
        #expect(result)
    }

    @Test("canEnableDynamicAddresses: allows when there are no siblings")
    func canEnableDynamicAddresses_allowsWithEmptyList() throws {
        // Given
        let candidate = try makeItem(.bitcoin(testnet: false), path: "m/84'/0'/0'/0/0")

        // When
        let result = DynamicAddressesCustomDerivationChecker.canEnableDynamicAddresses(
            for: candidate,
            existingTokens: []
        )

        // Then
        #expect(result)
    }

    @Test("canEnableDynamicAddresses: allows when candidate derivation path is nil")
    func canEnableDynamicAddresses_allowsWhenCandidatePathIsNil() throws {
        // Given
        let candidate = makeItem(.bitcoin(testnet: false), derivationPath: nil)
        let sibling = try makeItem(.bitcoin(testnet: false), path: "m/84'/0'/0'/0/0")

        // When
        let result = DynamicAddressesCustomDerivationChecker.canEnableDynamicAddresses(
            for: candidate,
            existingTokens: [sibling]
        )

        // Then
        #expect(result)
    }

    @Test("canEnableDynamicAddresses: allows when sibling derivation path is nil")
    func canEnableDynamicAddresses_allowsWhenSiblingPathIsNil() throws {
        // Given
        let candidate = try makeItem(.bitcoin(testnet: false), path: "m/84'/0'/0'/0/0")
        let sibling = makeItem(.bitcoin(testnet: false), derivationPath: nil)

        // When
        let result = DynamicAddressesCustomDerivationChecker.canEnableDynamicAddresses(
            for: candidate,
            existingTokens: [sibling]
        )

        // Then
        #expect(result)
    }
}

// MARK: - Helpers

private func makeItem(
    _ blockchain: Blockchain,
    path: String,
    settings: BlockchainSettings? = nil,
    token: Token? = nil
) throws -> TokenItem {
    let network = try BlockchainNetwork(
        blockchain,
        derivationPath: DerivationPath(rawPath: path),
        settings: settings
    )
    if let token {
        return .token(token, network)
    }
    return .blockchain(network)
}

private func makeItem(
    _ blockchain: Blockchain,
    derivationPath: DerivationPath?,
    settings: BlockchainSettings? = nil,
    token: Token? = nil
) -> TokenItem {
    let network = BlockchainNetwork(
        blockchain,
        derivationPath: derivationPath,
        settings: settings
    )
    if let token {
        return .token(token, network)
    }
    return .blockchain(network)
}

private func makeTestToken(contract: String) -> Token {
    Token(name: "Test", symbol: "TST", contractAddress: contract, decimalCount: 8)
}
