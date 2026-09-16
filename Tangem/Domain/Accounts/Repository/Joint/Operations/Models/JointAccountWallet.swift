//
//  JointAccountWallet.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

/// The wallet an operation of a joint account is made through, and what can be done with it.
/// - Note: Built by `JointAccountWalletBuilder` alone, off a single wallet model, so the token, the Safe and the key
/// cannot describe different wallets.
struct JointAccountWallet {
    var tokenItem: TokenItem {
        walletModel.tokenItem
    }

    var publicKey: Wallet.PublicKey {
        walletModel.publicKey
    }

    var safeWalletManagerOperationsService: (any SafeWalletManagerOperationsService)? {
        walletModel.safeWalletManagerOperationsService
    }

    var account: (any JointAccountModel)? {
        walletModel.account as? any JointAccountModel
    }

    private let walletModel: any WalletModel

    fileprivate init(walletModel: any WalletModel) {
        self.walletModel = walletModel
    }
}

// MARK: - Operations

extension JointAccountWallet {
    /// Registers the transfer as an operation of the account, with this member's signature already counted.
    func createOperation(transaction: BSDKTransaction) async throws -> JointAccountOperation {
        try await operationsService.createOperation(transaction: transaction, in: self)
    }

    /// Counts this member's signature towards the threshold.
    func sign(_ operation: JointAccountOperation) async throws {
        try await operationsService.signOperation(operation, in: self)
    }

    /// Declines the operation, which the initiator's own answer ends outright.
    func reject(_ operation: JointAccountOperation) async throws {
        try await operationsService.rejectOperation(operation, in: self)
    }

    /// Taken from the account rather than kept, so that a wallet handed out long ago acts through the account as it
    /// stands now.
    private var operationsService: JointAccountOperationsService {
        get throws {
            guard let account else {
                throw JointOperationError.accountUnavailable
            }

            return account.jointAccountOperationsService
        }
    }
}

// MARK: - Equatable protocol conformance

extension JointAccountWallet: Equatable {
    /// By the wallet it stands for, which is what an operation is made through.
    static func == (lhs: JointAccountWallet, rhs: JointAccountWallet) -> Bool {
        lhs.walletModel.id == rhs.walletModel.id
    }
}

// MARK: - Builder

struct JointAccountWalletBuilder {
    /// - Throws: `Error.notJointAccount` for a wallet of one of the wallet's own accounts, `Error.safeUnavailable`
    /// for one whose network has no Safe — an operation through either is one nobody could act on.
    func build(walletModel: any WalletModel) throws(Error) -> JointAccountWallet {
        guard walletModel.account is any JointAccountModel else {
            throw .notJointAccount
        }

        guard walletModel.safeWalletManagerOperationsService != nil else {
            throw .safeUnavailable
        }

        return JointAccountWallet(walletModel: walletModel)
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
