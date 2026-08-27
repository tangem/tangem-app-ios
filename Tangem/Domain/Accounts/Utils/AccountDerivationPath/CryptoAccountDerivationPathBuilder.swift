//
//  CryptoAccountDerivationPathBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct CryptoAccountDerivationPathBuilder {
    private let derivationIndex: Int
    private let derivationStyle: DerivationStyle?
    private let identity: CryptoAccountDerivationIdentity
    private let isMainAccount: Bool

    init(derivationIndex: Int, derivationStyle: DerivationStyle?) {
        self.derivationIndex = derivationIndex
        self.derivationStyle = derivationStyle

        identity = CryptoAccountDerivationIdentity(
            derivationIndex: derivationIndex,
            type: .crypto
        )
        isMainAccount = AccountModelUtils.isMainAccount(identity)
    }
}

// MARK: - AccountDerivationPathBuilder protocol conformance

extension CryptoAccountDerivationPathBuilder: AccountDerivationPathBuilder {
    func makeDerivationPath(
        basedOn derivationPath: DerivationPath?,
        for blockchain: Blockchain
    ) -> DerivationPath? {
        // The main account takes a token with a derivation of its own as it is
        if isMainAccount, let derivationPath {
            return derivationPath
        }

        if let derivationPath, let accountAwarePath = try? correctAccountDerivationNode(in: derivationPath, forBlockchain: blockchain) {
            return accountAwarePath
        }

        guard let defaultPath = defaultDerivationPath(forBlockchain: blockchain) else {
            // A wallet that derives nothing has no path of its own to offer, so the token keeps the one it came with
            return derivationPath
        }

        return try? correctAccountDerivationNode(in: defaultPath, forBlockchain: blockchain)
    }

    /// - Note: A path with too few nodes to name an account means the blockchain, and therefore everything of it, is
    /// custom, so what the blockchain derives by default stands in.
    func getTargetDerivationPath(for blockchain: Blockchain) -> DerivationPath? {
        guard let defaultPath = defaultDerivationPath(forBlockchain: blockchain) else {
            return nil
        }

        do {
            return try correctAccountDerivationNode(in: defaultPath, forBlockchain: blockchain)
        } catch .insufficientNodes {
            return defaultPath
        } catch {
            return nil
        }
    }

    func validateDerivationPath(
        _ derivationPath: DerivationPath?,
        for blockchain: Blockchain
    ) throws(AccountDerivationPathError) {
        // Some blockchains do not support any derivations other than the default one (for the main account).
        // An unreadable path names no account of ours, so it is not this check's business to reject a token over it
        if let derivationPath,
           let accountDerivationNode = try? accountDerivationNode(in: derivationPath, forBlockchain: blockchain),
           accountDerivationNode.rawIndex != UInt32(AccountModelUtils.mainAccountDerivationIndex),
           !blockchain.curve.supportsDerivation {
            throw .derivationNotSupported(blockchain.displayName)
        }

        // The main account takes a token with any derivation, or with none, as it is
        if isMainAccount {
            return
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

private extension CryptoAccountDerivationPathBuilder {
    func defaultDerivationPath(forBlockchain blockchain: Blockchain) -> DerivationPath? {
        derivationStyle.flatMap { blockchain.derivationPath(for: $0) }
    }

    func correctAccountDerivationNode(
        in derivationPath: DerivationPath,
        forBlockchain blockchain: Blockchain
    ) throws(AccountDerivationPathError) -> DerivationPath {
        do {
            let helper = AccountDerivationPathHelper(blockchain: blockchain)
            return try helper.makeDerivationPath(from: derivationPath, forAccountWithIndex: derivationIndex)
        } catch {
            throw AccountDerivationPathError(error)
        }
    }

    func accountDerivationNode(
        in derivationPath: DerivationPath,
        forBlockchain blockchain: Blockchain
    ) throws(AccountDerivationPathError) -> DerivationNode {
        do {
            let helper = AccountDerivationPathHelper(blockchain: blockchain)
            return try helper.extractAccountDerivationNode(from: derivationPath)
        } catch {
            throw AccountDerivationPathError(error)
        }
    }
}
