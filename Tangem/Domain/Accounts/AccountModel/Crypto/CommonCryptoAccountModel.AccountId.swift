//
//  CommonCryptoAccountModel.AccountId.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import TangemFoundation

typealias CryptoAccountModelId = CommonCryptoAccountModel.AccountId

extension CommonCryptoAccountModel {
    /// A specific identifier for the `CryptoAccountModel` type only. Other types of accounts must implement and use different id types.
    struct AccountId: Hashable {
        /// - Note: For serialization/deserialization purposes and backend communications.
        var rawValue: Data {
            let bytes = switch derivationIdentity.type {
            // The formula the backend has always minted the wallet's own accounts with, kept byte-for-byte so that
            // every existing account answers to the identifier it is already known by
            case .crypto: userWalletId.value + derivationIdentity.derivationIndex.bytes4

            // The suffix is all that keeps a joint account's identifier apart from the crypto one sharing its
            // derivation index
            case .joint: userWalletId.value + derivationIdentity.derivationIndex.bytes4 + Constants.jointSuffix.utf8
            }

            return bytes.getSHA256()
        }

        private let userWalletId: UserWalletId
        private let derivationIdentity: CryptoAccountDerivationIdentity

        init(
            userWalletId: UserWalletId,
            derivationIdentity: CryptoAccountDerivationIdentity
        ) {
            self.userWalletId = userWalletId
            self.derivationIdentity = derivationIdentity
        }
    }
}

// MARK: - AccountModelPersistentIdentifierConvertible protocol conformance

extension CommonCryptoAccountModel.AccountId: AccountModelPersistentIdentifierConvertible {
    func toPersistentIdentifier() -> AnyHashable {
        derivationIdentity.toPersistentIdentifier()
    }
}

// MARK: - CustomStringConvertible protocol conformance

extension CommonCryptoAccountModel.AccountId: CustomStringConvertible {
    var description: String {
        userWalletId.stringValue + "/\(derivationIdentity)"
    }
}

// MARK: - Constants

private extension CommonCryptoAccountModel.AccountId {
    enum Constants {
        /// Serves the backend's minting formula alone — the persistent identifier spells the kind through
        /// `AccountType.rawValue` on its own.
        static let jointSuffix = AccountType.joint.rawValue
    }
}
