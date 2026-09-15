//
//  JointAccountWallet.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

/// The wallet an operation is made through: the account it belongs to, the token it moves, the manager that reads the
/// Safe in that network and shapes the inner call, and the key the account signs with there.
/// - Note: Built by `JointAccountWalletBuilder` alone, off a single wallet model, so the token, the Safe and
/// the key cannot describe different wallets.
struct JointAccountWallet {
    let tokenItem: TokenItem
    let walletPublicKey: Wallet.PublicKey

    /// - Note: Weak because what hands out these operations is the account's own, and an operation that outlived the
    /// account it belongs to is nothing to act on.
    private(set) weak var account: (any JointAccountModel)?
    /// - Note: Weak for the same reason: the manager is the wallet model's, and an operation waiting in a list is not
    /// what should keep a wallet's manager alive.
    private(set) weak var safeOperationsService: (any SafeWalletManagerOperationsService)?

    fileprivate init(
        tokenItem: TokenItem,
        walletPublicKey: Wallet.PublicKey,
        account: any JointAccountModel,
        safeOperationsService: any SafeWalletManagerOperationsService
    ) {
        self.tokenItem = tokenItem
        self.walletPublicKey = walletPublicKey
        self.account = account
        self.safeOperationsService = safeOperationsService
    }
}

// MARK: - Equatable protocol conformance

extension JointAccountWallet: Equatable {
    static func == (lhs: JointAccountWallet, rhs: JointAccountWallet) -> Bool {
        lhs.tokenItem == rhs.tokenItem
    }
}

// MARK: - Builder

struct JointAccountWalletBuilder {
    /// - Throws: `Error.notJointAccount` for a wallet of one of the wallet's own accounts, `Error.safeUnavailable` for
    /// one whose network has no Safe to operate.
    func build(walletModel: any WalletModel) throws(Error) -> JointAccountWallet {
        guard let account = walletModel.account as? any JointAccountModel else {
            throw .notJointAccount
        }

        guard let safeOperationsService = walletModel.safeWalletManagerOperationsService else {
            throw .safeUnavailable
        }

        return JointAccountWallet(
            tokenItem: walletModel.tokenItem,
            walletPublicKey: walletModel.publicKey,
            account: account,
            safeOperationsService: safeOperationsService
        )
    }
}

// MARK: - Errors

extension JointAccountWalletBuilder {
    enum Error: Swift.Error {
        /// The wallet belongs to one of the wallet's own accounts, which has no operations to make.
        case notJointAccount
        /// The wallet's manager cannot read a Safe, which is any outside the EVM networks.
        case safeUnavailable
    }
}
