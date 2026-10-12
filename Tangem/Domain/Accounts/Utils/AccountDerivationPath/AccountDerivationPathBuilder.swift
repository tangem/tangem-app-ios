//
//  AccountDerivationPathBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

protocol AccountDerivationPathBuilder {
    /// The path the account holds the token at, made from the path the token came with, if any.
    /// - Returns: Nil when the account has no path to give the blockchain, in which case the token is kept without one.
    func makeDerivationPath(basedOn derivationPath: DerivationPath?, for blockchain: Blockchain) -> DerivationPath?

    /// The path the account's tokens of the blockchain are expected at, which is what tells a custom token from a
    /// regular one.
    func getTargetDerivationPath(for blockchain: Blockchain) -> DerivationPath?

    /// Checks that a token kept at this path may be held by the account: the path has to be one the account itself
    /// derives, and the blockchain's curve has to support deriving it in the first place.
    func validateDerivationPath(_ derivationPath: DerivationPath?, for blockchain: Blockchain) throws(AccountDerivationPathError)
}

// MARK: - Factory

enum AccountDerivationPathBuilderFactory {
    static func makeBuilder(
        forAccountWith derivationIdentity: CryptoAccountDerivationIdentity,
        derivationStyle: DerivationStyle?
    ) -> any AccountDerivationPathBuilder {
        switch derivationIdentity.type {
        case .crypto:
            return CryptoAccountDerivationPathBuilder(
                derivationIndex: derivationIdentity.derivationIndex,
                derivationStyle: derivationStyle
            )
        case .joint:
            return JointAccountDerivationPathBuilder(derivationIndex: derivationIdentity.derivationIndex)
        }
    }
}

// MARK: - Error

enum AccountDerivationPathError: Swift.Error, LocalizedError, Equatable {
    case insufficientNodes(required: Int, actual: Int, blockchain: String)
    case accountsUnavailableForBlockchain(_ blockchain: String)
    case jointAccountsUnavailableForBlockchain(_ blockchain: String)
    case notAJointAccountDerivationPath(_ blockchain: String)
    case accountDerivationNodeMismatch(expected: UInt32, actual: UInt32)
    case derivationNotSupported(_ blockchain: String)
    case derivationPathNotFound

    /// The wallet's own accounts are derived by `AccountDerivationPathHelper`, which answers in its own terms.
    init(_ error: AccountDerivationPathHelper.Error) {
        switch error {
        case .insufficientNodes(let required, let actual, let blockchain):
            self = .insufficientNodes(required: required, actual: actual, blockchain: blockchain)
        case .accountsUnavailableForBlockchain(let blockchain):
            self = .accountsUnavailableForBlockchain(blockchain)
        }
    }

    var errorDescription: String? {
        switch self {
        case .insufficientNodes(let required, let actual, let blockchain):
            return "Derivation path for \(blockchain) has insufficient nodes: expected at least \(required), got \(actual)"
        case .accountsUnavailableForBlockchain(let blockchain):
            return "Blockchain \(blockchain) does not support custom derivation paths and accounts."
        case .jointAccountsUnavailableForBlockchain(let blockchain):
            return "Blockchain \(blockchain) cannot hold anything of a joint account, which lives at a single EVM address."
        case .notAJointAccountDerivationPath(let blockchain):
            return "Derivation path for \(blockchain) is not the one a joint account derives its tokens at."
        case .accountDerivationNodeMismatch(let expected, let actual):
            return "Derivation path names the account \(actual) rather than \(expected), which derives it."
        case .derivationNotSupported(let blockchain):
            return "Blockchain \(blockchain) does not support deriving anything but its default path."
        case .derivationPathNotFound:
            return "The token brings no derivation path, and the account cannot place it without one."
        }
    }
}
