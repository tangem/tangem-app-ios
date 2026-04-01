//
//  DynamicAddressesDerivationHelperTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
import TangemSdk
@testable import BlockchainSdk

@Suite("DynamicAddressesDerivationHelper Tests")
struct DynamicAddressesDerivationHelperTests {
    /// Used derivations:
    ///   m/84'/0'/0'/0/0, m/84'/0'/0'/1/0,
    ///   m/84'/0'/0'/0/1, m/84'/0'/0'/1/1,
    ///   m/84'/0'/0'/0/2, m/84'/0'/0'/1/2,
    ///   m/84'/0'/0'/0/3, m/84'/0'/0'/0/7
    /// Expected receive (external): m/84'/0'/0'/0/4
    /// Expected change (internal):  m/84'/0'/0'/1/3
    @Test("REQ-004: Resolve external receive address with gaps in used indices")
    func resolveExternalAddressWithGaps() throws {
        // Arrange
        let accountPath = try DerivationPath(rawPath: "m/84'/0'/0'")
        let usedDerivations = try [
            "m/84'/0'/0'/0/0",
            "m/84'/0'/0'/1/0",
            "m/84'/0'/0'/0/1",
            "m/84'/0'/0'/1/1",
            "m/84'/0'/0'/0/2",
            "m/84'/0'/0'/1/2",
            "m/84'/0'/0'/0/3",
            "m/84'/0'/0'/0/7",
        ].map { try DerivationPath(rawPath: $0) }

        let helper = DynamicAddressesDerivationHelper(
            accountDerivationPath: accountPath,
            usedDerivations: usedDerivations
        )

        // Act
        let receivePath = helper.resolveDerivationPath(chain: .external)

        // Assert
        let expectedPath = try DerivationPath(rawPath: "m/84'/0'/0'/0/4")
        #expect(receivePath == expectedPath, "Expected first unused external index 4, got \(receivePath.rawPath)")
    }

    @Test("REQ-004: Resolve internal change address")
    func resolveInternalChangeAddress() throws {
        // Arrange
        let accountPath = try DerivationPath(rawPath: "m/84'/0'/0'")
        let usedDerivations = try [
            "m/84'/0'/0'/0/0",
            "m/84'/0'/0'/1/0",
            "m/84'/0'/0'/0/1",
            "m/84'/0'/0'/1/1",
            "m/84'/0'/0'/0/2",
            "m/84'/0'/0'/1/2",
            "m/84'/0'/0'/0/3",
            "m/84'/0'/0'/0/7",
        ].map { try DerivationPath(rawPath: $0) }

        let helper = DynamicAddressesDerivationHelper(
            accountDerivationPath: accountPath,
            usedDerivations: usedDerivations
        )

        // Act
        let changePath = helper.resolveDerivationPath(chain: .internal)

        // Assert
        let expectedPath = try DerivationPath(rawPath: "m/84'/0'/0'/1/3")
        #expect(changePath == expectedPath, "Expected first unused internal index 3, got \(changePath.rawPath)")
    }

    // MARK: - UC-2 Example 2.1: Custom derivations with gaps

    /// From UC-2, Example 2.1:
    /// Used: m/44'/0'/0'/0/0 (base), m/44'/0'/0'/0/1, m/44'/0'/0'/0/4
    /// Expected receive: m/44'/0'/0'/0/2 (first unused by order)
    @Test("UC-2 Example 2.1: First unused address with non-contiguous used indices")
    func resolveFirstUnusedWithNonContiguousIndices() throws {
        // Arrange
        let accountPath = try DerivationPath(rawPath: "m/44'/0'/0'")
        let usedDerivations = try [
            "m/44'/0'/0'/0/0", // base address is always used
            "m/44'/0'/0'/0/1",
            "m/44'/0'/0'/0/4",
        ].map { try DerivationPath(rawPath: $0) }

        let helper = DynamicAddressesDerivationHelper(
            accountDerivationPath: accountPath,
            usedDerivations: usedDerivations
        )

        // Act
        let receivePath = helper.resolveDerivationPath(chain: .external)

        // Assert
        let expectedPath = try DerivationPath(rawPath: "m/44'/0'/0'/0/2")
        #expect(receivePath == expectedPath, "Expected first unused external index 2, got \(receivePath.rawPath)")
    }

    // MARK: - UC-2 Example 1: Sequential from base address

    /// From UC-2, Example 1:
    /// Only base address m/x'/x'/x'/0/0 is used.
    /// Expected receive: m/84'/0'/0'/0/1
    @Test("UC-2 Example 1: Next address after only base address used")
    func resolveNextAfterBaseAddress() throws {
        // Arrange
        let accountPath = try DerivationPath(rawPath: "m/84'/0'/0'")
        let usedDerivations = try [
            "m/84'/0'/0'/0/0",
        ].map { try DerivationPath(rawPath: $0) }

        let helper = DynamicAddressesDerivationHelper(
            accountDerivationPath: accountPath,
            usedDerivations: usedDerivations
        )

        // Act
        let receivePath = helper.resolveDerivationPath(chain: .external)

        // Assert
        let expectedPath = try DerivationPath(rawPath: "m/84'/0'/0'/0/1")
        #expect(receivePath == expectedPath, "Expected external index 1, got \(receivePath.rawPath)")
    }

    /// After m/x'/x'/x'/0/1 is used, next receive should be m/x'/x'/x'/0/2
    @Test("UC-2 Example 1: Sequential increment after two used addresses")
    func resolveSequentialIncrement() throws {
        // Arrange
        let accountPath = try DerivationPath(rawPath: "m/84'/0'/0'")
        let usedDerivations = try [
            "m/84'/0'/0'/0/0",
            "m/84'/0'/0'/0/1",
        ].map { try DerivationPath(rawPath: $0) }

        let helper = DynamicAddressesDerivationHelper(
            accountDerivationPath: accountPath,
            usedDerivations: usedDerivations
        )

        // Act
        let receivePath = helper.resolveDerivationPath(chain: .external)

        // Assert
        let expectedPath = try DerivationPath(rawPath: "m/84'/0'/0'/0/2")
        #expect(receivePath == expectedPath, "Expected external index 2, got \(receivePath.rawPath)")
    }

    // MARK: - Edge cases

    @Test("No used derivations returns index 0")
    func resolveWithNoUsedDerivations() throws {
        // Arrange
        let accountPath = try DerivationPath(rawPath: "m/84'/0'/0'")
        let helper = DynamicAddressesDerivationHelper(
            accountDerivationPath: accountPath,
            usedDerivations: []
        )

        // Act
        let receivePath = helper.resolveDerivationPath(chain: .external)
        let changePath = helper.resolveDerivationPath(chain: .internal)

        // Assert
        let expectedReceive = try DerivationPath(rawPath: "m/84'/0'/0'/0/0")
        let expectedChange = try DerivationPath(rawPath: "m/84'/0'/0'/1/0")
        #expect(receivePath == expectedReceive, "Expected external index 0, got \(receivePath.rawPath)")
        #expect(changePath == expectedChange, "Expected internal index 0, got \(changePath.rawPath)")
    }

    @Test("Only internal chain used, external starts at 0")
    func resolveExternalWhenOnlyInternalUsed() throws {
        // Arrange
        let accountPath = try DerivationPath(rawPath: "m/84'/0'/0'")
        let usedDerivations = try [
            "m/84'/0'/0'/1/0",
            "m/84'/0'/0'/1/1",
        ].map { try DerivationPath(rawPath: $0) }

        let helper = DynamicAddressesDerivationHelper(
            accountDerivationPath: accountPath,
            usedDerivations: usedDerivations
        )

        // Act
        let receivePath = helper.resolveDerivationPath(chain: .external)

        // Assert
        let expectedPath = try DerivationPath(rawPath: "m/84'/0'/0'/0/0")
        #expect(receivePath == expectedPath, "Expected external index 0 when no external used, got \(receivePath.rawPath)")
    }

    @Test("Hardened nodes in derivation are ignored for chain matching")
    func resolveIgnoresHardenedNodes() throws {
        // Arrange
        let accountPath = try DerivationPath(rawPath: "m/84'/0'/0'")
        // Paths with hardened change/index nodes should be ignored by parseUsedIndices
        let usedDerivations = try [
            "m/84'/0'/0'/0/0",
            "m/84'/0'/0'/0'/1'", // Hardened nodes - should be ignored
        ].map { try DerivationPath(rawPath: $0) }

        let helper = DynamicAddressesDerivationHelper(
            accountDerivationPath: accountPath,
            usedDerivations: usedDerivations
        )

        // Act
        let receivePath = helper.resolveDerivationPath(chain: .external)

        // Assert — only index 0 should be counted as used
        let expectedPath = try DerivationPath(rawPath: "m/84'/0'/0'/0/1")
        #expect(receivePath == expectedPath, "Expected external index 1, hardened path should be ignored, got \(receivePath.rawPath)")
    }

    @Test("Short derivation paths (fewer than 2 nodes) are ignored")
    func resolveIgnoresShortPaths() throws {
        // Arrange
        let accountPath = try DerivationPath(rawPath: "m/84'/0'/0'")
        let usedDerivations = try [
            "m/84'/0'/0'/0/0",
            "m/0", // Only 1 node — should be ignored
        ].map { try DerivationPath(rawPath: $0) }

        let helper = DynamicAddressesDerivationHelper(
            accountDerivationPath: accountPath,
            usedDerivations: usedDerivations
        )

        // Act
        let receivePath = helper.resolveDerivationPath(chain: .external)

        // Assert
        let expectedPath = try DerivationPath(rawPath: "m/84'/0'/0'/0/1")
        #expect(receivePath == expectedPath, "Expected external index 1, got \(receivePath.rawPath)")
    }

    @Test("Different account paths (BIP-44 vs BIP-84)")
    func resolveWithBIP44AccountPath() throws {
        // Arrange
        let accountPath = try DerivationPath(rawPath: "m/44'/0'/0'")
        let usedDerivations = try [
            "m/44'/0'/0'/0/0",
            "m/44'/0'/0'/0/1",
            "m/44'/0'/0'/0/2",
            "m/44'/0'/0'/1/0",
        ].map { try DerivationPath(rawPath: $0) }

        let helper = DynamicAddressesDerivationHelper(
            accountDerivationPath: accountPath,
            usedDerivations: usedDerivations
        )

        // Act
        let receivePath = helper.resolveDerivationPath(chain: .external)
        let changePath = helper.resolveDerivationPath(chain: .internal)

        // Assert
        let expectedReceive = try DerivationPath(rawPath: "m/44'/0'/0'/0/3")
        let expectedChange = try DerivationPath(rawPath: "m/44'/0'/0'/1/1")
        #expect(receivePath == expectedReceive, "Expected external index 3, got \(receivePath.rawPath)")
        #expect(changePath == expectedChange, "Expected internal index 1, got \(changePath.rawPath)")
    }
}
