//
//  JointAccountDerivationPathBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct JointAccountDerivationPathBuilder {
    private let derivationIndex: Int

    init(derivationIndex: Int) {
        self.derivationIndex = derivationIndex
    }
}

// MARK: - AccountDerivationPathBuilder protocol conformance

extension JointAccountDerivationPathBuilder: AccountDerivationPathBuilder {
    /// - Parameter derivationPath: Unused: the account derives everything it holds at a path of its own, never
    /// relative to the one a token came with.
    func makeDerivationPath(
        basedOn derivationPath: DerivationPath?,
        for blockchain: Blockchain
    ) -> DerivationPath? {
        try? makeAccountDerivationPath(forBlockchain: blockchain)
    }

    /// - Note: The tokens are expected exactly where they are derived — at the account's own path.
    func getTargetDerivationPath(for blockchain: Blockchain) -> DerivationPath? {
        try? makeAccountDerivationPath(forBlockchain: blockchain)
    }

    func validateDerivationPath(
        _ derivationPath: DerivationPath?,
        for blockchain: Blockchain
    ) throws(AccountDerivationPathError) {
        // The account never sits at a blockchain's default path, so its tokens always need a curve that supports derivation
        guard blockchain.curve.supportsDerivation else {
            throw .derivationNotSupported(blockchain.displayName)
        }

        guard JointAccountSupportedBlockchains.contains(blockchain) else {
            throw .jointAccountsUnavailableForBlockchain(blockchain.displayName)
        }

        guard let derivationPath else {
            throw .derivationPathNotFound
        }

        let accountDerivationNode = try accountDerivationNode(in: derivationPath, forBlockchain: blockchain)
        let expectedDerivationIndex = UInt32(derivationIndex)

        guard accountDerivationNode.rawIndex == expectedDerivationIndex else {
            throw .accountDerivationNodeMismatch(expected: expectedDerivationIndex, actual: accountDerivationNode.rawIndex)
        }
    }
}

// MARK: - Private implementation

private extension JointAccountDerivationPathBuilder {
    /// - Note: An account is a contract living at one and the same address across the EVM networks, and nowhere else,
    /// so nothing outside them can be held in one.
    /// - Warning: A part of the contract with the backend, which syncs the token list between the members by this path.
    func makeAccountDerivationPath(
        forBlockchain blockchain: Blockchain
    ) throws(AccountDerivationPathError) -> DerivationPath {
        guard blockchain.isEvm else {
            let displayName = blockchain.displayName
            AppLogger.warning("Attempting to derive a joint account's token for unsupported blockchain: \(displayName)")
            throw .jointAccountsUnavailableForBlockchain(displayName)
        }

        return JointAccountKeyPath.derivationPath(forAccountAtIndex: derivationIndex)
    }

    /// - Note: Makes sure the path is a joint one before reading the node: a path of the wallet's own accounts keeps
    /// something else entirely at that place, and for the EVM networks it keeps it at the very same one.
    func accountDerivationNode(
        in derivationPath: DerivationPath,
        forBlockchain blockchain: Blockchain
    ) throws(AccountDerivationPathError) -> DerivationNode {
        let nodeIndex = Constants.accountIndexNodeIndex
        let actualNodesCount = derivationPath.nodes.count
        let requiredNodesCount = nodeIndex + 1

        guard actualNodesCount >= requiredNodesCount else {
            throw .insufficientNodes(required: requiredNodesCount, actual: actualNodesCount, blockchain: blockchain.displayName)
        }

        let accountDerivationNode = derivationPath.nodes[nodeIndex]
        let expectedPath = JointAccountKeyPath.derivationPath(forAccountAtIndex: Int(accountDerivationNode.rawIndex))

        guard derivationPath == expectedPath else {
            throw .notAJointAccountDerivationPath(blockchain.displayName)
        }

        return accountDerivationNode
    }
}

// MARK: - Constants

private extension JointAccountDerivationPathBuilder {
    enum Constants {
        /// 5th node `index` (m / 44' / 60' / 888888' / 0 / index), the account's own number: the `account` node is
        /// taken by the value that makes the path a joint one in the first place.
        static let accountIndexNodeIndex = 4
    }
}
