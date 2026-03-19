//
//  AccountDerivationPathHelperTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Testing
import enum BlockchainSdk.Blockchain
import struct TangemSdk.DerivationPath
@testable import Tangem

@Suite("AccountDerivationPathHelper Tests")
struct AccountDerivationPathHelperTests {
    // MARK: - Private properties

    private let bitcoinMainnet = Blockchain.bitcoin(testnet: false)
    private let ethereumMainnet = Blockchain.ethereum(testnet: false)
    private let solanaMainnet = Blockchain.solana(curve: .ed25519, testnet: false)
    private let tronMainnet = Blockchain.tron(testnet: false)

    // MARK: - Account Node Extraction Tests

    @Test(
        "Account node extraction",
        arguments: [
            provideEthLikeTestCases(),
            provideUTXOTestCases(),
            provideOtherBlockchainTests(),
        ].flattened()
    )
    func testAccountNodeExtraction(_ testCase: TestCase) async throws {
        // Arrange
        let helper = AccountDerivationPathHelper(blockchain: testCase.blockchain)
        let derivationPath = try DerivationPath(rawPath: testCase.derivationPath)

        // Act
        let actual = try helper.extractAccountDerivationNode(from: derivationPath)

        // Assert
        #expect(actual.rawIndex == testCase.expected, "Failed for blockchain: \(testCase.blockchain), path: \(testCase.derivationPath)")
    }

    @Test("Extraction with short derivation path throws insufficientNodes error")
    func testExtractionOfShortDerivationPathThrows() async throws {
        // Arrange
        let helper = AccountDerivationPathHelper(blockchain: bitcoinMainnet)
        let derivationPath = try DerivationPath(rawPath: "m/44'/0'") // Only 2 nodes, need at least 3

        // Act & Assert
        do {
            _ = try helper.extractAccountDerivationNode(from: derivationPath)
            Issue.record("Expected error to be thrown")
        } catch {
            switch error {
            case .insufficientNodes:
                break
            default:
                Issue.record("Unexpected error case: \(error)")
            }
        }
    }

    @Test("Extraction for unsupported blockchain throws accountsUnavailableForBlockchain error")
    func testExtractionForUnsupportedBlockchainThrows() async throws {
        // Arrange - Chia doesn't support accounts
        let chiaMainnet = Blockchain.chia(testnet: false)
        let helper = AccountDerivationPathHelper(blockchain: chiaMainnet)
        let derivationPath = try DerivationPath(rawPath: "m/12381'/8444'/0'/0")

        // Act & Assert
        do {
            _ = try helper.extractAccountDerivationNode(from: derivationPath)
            Issue.record("Expected error to be thrown")
        } catch {
            switch error {
            case .accountsUnavailableForBlockchain:
                break
            default:
                Issue.record("Unexpected error case: \(error)")
            }
        }
    }

    @Test("Extract account node from standard BIP44 path")
    func extractAccountNodeFromStandardBIP44Path() throws {
        let helper = AccountDerivationPathHelper(blockchain: bitcoinMainnet)
        let derivationPath = try DerivationPath(rawPath: "m/44'/0'/11'/0/0")

        let accountNode = try helper.extractAccountDerivationNode(from: derivationPath)
        #expect(accountNode.rawIndex == 11)
    }

    @Test("Extract account node from different account indices", arguments: [
        ("m/44'/0'/1'/0/0", 1),
        ("m/44'/0'/5'/0/0", 5),
        ("m/44'/0'/10'/0/0", 10),
    ])
    func extractAccountNodeFromDifferentIndices(pathString: String, expectedIndex: UInt32) throws {
        let helper = AccountDerivationPathHelper(blockchain: bitcoinMainnet)
        let derivationPath = try DerivationPath(rawPath: pathString)

        let accountNode = try helper.extractAccountDerivationNode(from: derivationPath)
        #expect(accountNode.rawIndex == expectedIndex)
    }

    /// See Accounts-REQ-App-006 for details.
    @Test("Extract account node from standard EVM blockchain path")
    func extractAccountNodeFromStandardEVMPath() throws {
        let helper = AccountDerivationPathHelper(blockchain: ethereumMainnet)
        let derivationPath = try DerivationPath(rawPath: "m/44'/60'/0'/0/10")

        let accountNode = try helper.extractAccountDerivationNode(from: derivationPath)
        #expect(accountNode.rawIndex == 10)
    }

    /// See Accounts-REQ-App-006 for details.
    @Test("Extract account node from non-standard EVM blockchain path")
    func extractAccountNodeFromNonStandardEVMPath() throws {
        let helper = AccountDerivationPathHelper(blockchain: ethereumMainnet)
        let derivationPath = try DerivationPath(rawPath: "m/44'/9001'/11'/0/10")

        let accountNode = try helper.extractAccountDerivationNode(from: derivationPath)
        #expect(accountNode.rawIndex == 11)
    }

    @Test("Extract account node from Solana path")
    func extractAccountNodeFromSolanaPath() throws {
        let helper = AccountDerivationPathHelper(blockchain: solanaMainnet)
        let derivationPath = try DerivationPath(rawPath: "m/44'/501'/10'")

        let accountNode = try helper.extractAccountDerivationNode(from: derivationPath)
        #expect(accountNode.rawIndex == 10)
    }

    @Test("Extract account node from Tron path")
    func extractAccountNodeFromTronPath() throws {
        let helper = AccountDerivationPathHelper(blockchain: tronMainnet)
        let derivationPath = try DerivationPath(rawPath: "m/44'/195'/10'/0/0")

        let accountNode = try helper.extractAccountDerivationNode(from: derivationPath)
        #expect(accountNode.rawIndex == 10)
    }

    // MARK: - Path Creation Tests

    @Test("Create derivation path with different account index")
    func createDerivationPathWithDifferentAccountIndex() throws {
        let helper = AccountDerivationPathHelper(blockchain: bitcoinMainnet)
        let originalPath = try DerivationPath(rawPath: "m/44'/0'/0'/0/0")

        let newPath = try helper.makeDerivationPath(from: originalPath, forAccountWithIndex: 2)
        #expect(newPath.rawPath == "m/44'/0'/2'/0/0")
    }

    @Test("Create derivation path with various account indices", arguments: [1, 5, 10, 50])
    func createDerivationPathWithVariousIndices(accountIndex: Int) throws {
        let helper = AccountDerivationPathHelper(blockchain: bitcoinMainnet)
        let originalPath = try DerivationPath(rawPath: "m/44'/0'/0'/0/0")

        let newPath = try helper.makeDerivationPath(from: originalPath, forAccountWithIndex: accountIndex)
        let expectedPath = "m/44'/0'/\(accountIndex)'/0/0"
        #expect(newPath.rawPath == expectedPath)
    }

    /// See Accounts-REQ-App-006 for details.
    @Test("Create standard EVM blockchain derivation path with account index")
    func createStandardEVMDerivationPathWithAccountIndex() throws {
        let helper = AccountDerivationPathHelper(blockchain: ethereumMainnet)
        let originalPath = try DerivationPath(rawPath: "m/44'/60'/0'/0/0")

        let newPath = try helper.makeDerivationPath(from: originalPath, forAccountWithIndex: 3)
        #expect(newPath.rawPath == "m/44'/60'/0'/0/3")
    }

    /// See Accounts-REQ-App-006 for details.
    @Test("Create non-standard EVM blockchain derivation path with account index")
    func createNonStandardEVMDerivationPathWithAccountIndex() throws {
        let helper = AccountDerivationPathHelper(blockchain: ethereumMainnet)
        let originalPath = try DerivationPath(rawPath: "m/44'/9001'/0'/0/7")

        let newPath = try helper.makeDerivationPath(from: originalPath, forAccountWithIndex: 5)
        #expect(newPath.rawPath == "m/44'/9001'/5'/0/7")
    }

    @Test("Create Solana derivation path with account index")
    func createSolanaDerivationPathWithAccountIndex() throws {
        let helper = AccountDerivationPathHelper(blockchain: solanaMainnet)
        let originalPath = try DerivationPath(rawPath: "m/44'/501'/0'")

        let newPath = try helper.makeDerivationPath(from: originalPath, forAccountWithIndex: 4)
        #expect(newPath.rawPath == "m/44'/501'/4'")
    }

    @Test("Create Tron derivation path with account index")
    func createTronDerivationPathWithAccountIndex() throws {
        let helper = AccountDerivationPathHelper(blockchain: tronMainnet)
        let originalPath = try DerivationPath(rawPath: "m/44'/195'/0'/0/0")

        let newPath = try helper.makeDerivationPath(from: originalPath, forAccountWithIndex: 44)
        #expect(newPath.rawPath == "m/44'/195'/44'/0/0")
    }

    // MARK: - Account Availability Tests

    @Test("Various blockchains account support", arguments: Blockchain.allMainnetCases)
    func variousBlockchainsAccountSupport(blockchain: Blockchain) {
        let helper = AccountDerivationPathHelper(blockchain: blockchain)

        // For now, accounts available for all blockchains except Chia
        let areAccountsAvailable = switch blockchain {
        case .chia:
            false
        default:
            true
        }

        #expect(helper.areAccountsAvailableForBlockchain() == areAccountsAvailable)
    }

    // MARK: - Edge Cases and Error Handling

    @Test("Make derivation path with zero account index")
    func makeDerivationPathWithZeroAccountIndex() throws {
        let helper = AccountDerivationPathHelper(blockchain: bitcoinMainnet)
        let derivationPath = try DerivationPath(rawPath: "m/44'/0'/5'/0/0")

        let newPath = try helper.makeDerivationPath(from: derivationPath, forAccountWithIndex: 0)
        #expect(newPath.rawPath == "m/44'/0'/0'/0/0")
    }

    @Test("Make derivation path with large account index")
    func makeDerivationPathWithLargeAccountIndex() throws {
        let helper = AccountDerivationPathHelper(blockchain: bitcoinMainnet)
        let derivationPath = try DerivationPath(rawPath: "m/44'/0'/0'/0/0")

        let newPath = try helper.makeDerivationPath(from: derivationPath, forAccountWithIndex: 999)
        #expect(newPath.rawPath == "m/44'/0'/999'/0/0")
    }

    @Test("Make derivation path throws for short path")
    func makeDerivationPathThrowsForShortPath() throws {
        let helper = AccountDerivationPathHelper(blockchain: bitcoinMainnet)
        let derivationPath = try DerivationPath(rawPath: "m/44'/0'") // Only 2 nodes

        do {
            _ = try helper.makeDerivationPath(from: derivationPath, forAccountWithIndex: 1)
            Issue.record("Expected error to be thrown")
        } catch {
            switch error {
            case .insufficientNodes:
                break
            default:
                Issue.record("Unexpected error case: \(error)")
            }
        }
    }

    @Test("EVM path with insufficient nodes for address index throws")
    func evmPathWithInsufficientNodesThrows() throws {
        let helper = AccountDerivationPathHelper(blockchain: ethereumMainnet)
        // Standard EVM path (44'/60') requires address_index at position 4, but this path has only 4 nodes (indices 0-3)
        let derivationPath = try DerivationPath(rawPath: "m/44'/60'/0'/0")

        do {
            _ = try helper.extractAccountDerivationNode(from: derivationPath)
            Issue.record("Expected error to be thrown")
        } catch {
            switch error {
            case .insufficientNodes:
                break
            default:
                Issue.record("Unexpected error case: \(error)")
            }
        }
    }

    // MARK: - Different Blockchain Types Tests

    @Test("Helper consistency across multiple operations")
    func helperConsistencyAcrossMultipleOperations() throws {
        let helper = AccountDerivationPathHelper(blockchain: bitcoinMainnet)
        let originalPath = try DerivationPath(rawPath: "m/44'/0'/0'/0/0")

        // Create a new path and extract its account node
        let newPath = try helper.makeDerivationPath(from: originalPath, forAccountWithIndex: 7)
        let extractedNode = try helper.extractAccountDerivationNode(from: newPath)

        #expect(extractedNode.rawIndex == 7)
        #expect(newPath.rawPath == "m/44'/0'/7'/0/0")

        // Create another path from the extracted path
        let anotherPath = try helper.makeDerivationPath(from: newPath, forAccountWithIndex: 15)
        #expect(anotherPath.rawPath == "m/44'/0'/15'/0/0")
    }

    // MARK: - Specific Error Type Tests

    @Test("Extraction throws insufficientNodes with correct details")
    func extractionThrowsInsufficientNodesWithCorrectDetails() throws {
        let helper = AccountDerivationPathHelper(blockchain: bitcoinMainnet)
        let derivationPath = try DerivationPath(rawPath: "m/44'/0'") // Only 2 nodes

        do {
            _ = try helper.extractAccountDerivationNode(from: derivationPath)
            Issue.record("Expected error to be thrown")
        } catch {
            switch error {
            case .insufficientNodes(let required, let actual, let blockchain):
                #expect(required == 3)
                #expect(actual == 2)
                #expect(blockchain == "Bitcoin")
            default:
                Issue.record("Unexpected error case: \(error)")
            }
        }
    }

    @Test("Extraction throws accountsUnavailableForBlockchain with correct details")
    func extractionThrowsAccountsUnavailableWithCorrectDetails() throws {
        let chiaMainnet = Blockchain.chia(testnet: false)
        let helper = AccountDerivationPathHelper(blockchain: chiaMainnet)
        let derivationPath = try DerivationPath(rawPath: "m/12381'/8444'/0'/0")

        do {
            _ = try helper.extractAccountDerivationNode(from: derivationPath)
            Issue.record("Expected error to be thrown")
        } catch {
            switch error {
            case .accountsUnavailableForBlockchain(let blockchain):
                #expect(blockchain == chiaMainnet.displayName)
            default:
                Issue.record("Unexpected error case: \(error)")
            }
        }
    }
}

// MARK: - Test Data Providers

/// Implemented as global function since buggy SwiftTesting crashes on static methods.
private func provideEthLikeTestCases() -> [AccountDerivationPathHelperTests.TestCase] {
    return [
        // Tezos blockchain
        AccountDerivationPathHelperTests.TestCase(blockchain: .tezos(curve: .secp256k1), derivationPath: "m/44'/1729'/1'/0/0", expected: 1),
        AccountDerivationPathHelperTests.TestCase(blockchain: .tezos(curve: .secp256k1), derivationPath: "m/44'/1729'/1'/0", expected: 1),
        AccountDerivationPathHelperTests.TestCase(blockchain: .tezos(curve: .secp256k1), derivationPath: "m/44'/1729'/1'", expected: 1),

        // Quai blockchain
        AccountDerivationPathHelperTests.TestCase(blockchain: .quai(testnet: false), derivationPath: "m/44'/994'/1'/0", expected: 1),
        AccountDerivationPathHelperTests.TestCase(blockchain: .quai(testnet: false), derivationPath: "m/44'/994'/1'", expected: 1),

        // Ethereum-like blockchain
        AccountDerivationPathHelperTests.TestCase(blockchain: .ethereum(testnet: false), derivationPath: "m/44'/60'/0'/0/1", expected: 1),
    ]
}

/// Implemented as global function since buggy SwiftTesting crashes on static methods.
private func provideUTXOTestCases() -> [AccountDerivationPathHelperTests.TestCase] {
    return [
        // Bitcoin blockchain
        AccountDerivationPathHelperTests.TestCase(blockchain: .bitcoin(testnet: false), derivationPath: "m/44'/0'/1'/0/0", expected: 1),
        AccountDerivationPathHelperTests.TestCase(blockchain: .bitcoin(testnet: false), derivationPath: "m/44'/0'/1'/0", expected: 1),
        AccountDerivationPathHelperTests.TestCase(blockchain: .bitcoin(testnet: false), derivationPath: "m/44'/0'/1'", expected: 1),
    ]
}

/// Implemented as global function since buggy SwiftTesting crashes on static methods.
private func provideOtherBlockchainTests() -> [AccountDerivationPathHelperTests.TestCase] {
    return [
        // Solana blockchain
        AccountDerivationPathHelperTests.TestCase(blockchain: .solana(curve: .ed25519_slip0010, testnet: false), derivationPath: "m/44'/501'/1'", expected: 1),

        // Cardano blockchain
        AccountDerivationPathHelperTests.TestCase(blockchain: .cardano(extended: false), derivationPath: "m/1852'/1815'/1'/0/0", expected: 1),
        AccountDerivationPathHelperTests.TestCase(blockchain: .cardano(extended: false), derivationPath: "m/1852'/1815'/1'/0", expected: 1),
        AccountDerivationPathHelperTests.TestCase(blockchain: .cardano(extended: false), derivationPath: "m/1852'/1815'/1'", expected: 1),

        // Tron blockchain
        AccountDerivationPathHelperTests.TestCase(blockchain: .tron(testnet: false), derivationPath: "m/44'/195'/1'/0/0", expected: 1),
        AccountDerivationPathHelperTests.TestCase(blockchain: .tron(testnet: false), derivationPath: "m/44'/195'/1'/0", expected: 1),
        AccountDerivationPathHelperTests.TestCase(blockchain: .tron(testnet: false), derivationPath: "m/44'/195'/1'", expected: 1),
    ]
}

// MARK: - Auxiliary types

extension AccountDerivationPathHelperTests {
    struct TestCase {
        let blockchain: Blockchain
        let derivationPath: String
        let expected: UInt32?
    }
}
