//
//  JointAccountInCryptoMerger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Puts a joint account back together out of the halves it is kept in: the entry the wallet's account list holds for
/// it, which is where its name, its icon and its tokens live, the record of its own, which carries the members and the
/// rules they operate it by, and the invites it was handed when it was created.
struct JointAccountInCryptoMerger {
    /// - Parameter cryptoAccounts: The entries the account list holds for the joint accounts, and those alone.
    /// - Note: An account whose record has not arrived yet is left out rather than shown half-built. The record comes
    /// from a source of its own, and the list is put together again once it does.
    func merge(
        _ cryptoAccounts: [any CryptoAccountModel],
        with storedJointAccounts: [StoredJointAccount],
        invites storedInvites: [StoredJointAccountInvites]
    ) -> [any JointAccountModel] {
        // Keyed without regard to the letter case, the way this identifier is matched everywhere else
        let storedAccountsKeyedByCryptoAccountIds = storedJointAccounts.keyedFirst { $0.cryptoAccountId.lowercased() }
        let invitesKeyedByCryptoAccountIds = storedInvites.keyedFirst { $0.cryptoAccountId.lowercased() }

        return cryptoAccounts.compactMap { cryptoAccount -> (any JointAccountModel)? in
            let cryptoAccountId = cryptoAccount.id
            let identifier = cryptoAccountId.rawValue.hexString.lowercased()

            guard let storedJointAccount = storedAccountsKeyedByCryptoAccountIds[identifier] else {
                JointAccountsLogger.warning("Nothing is stored yet for the joint account '\(cryptoAccount.id)'")
                return nil
            }

            let invites = invitesKeyedByCryptoAccountIds[identifier]?.invites ?? []
            let members = storedJointAccount.members.map { member in
                JointAccountMember(name: member.name, address: member.address, role: member.role)
            }

            let config = JointAccountConfig(
                membersCount: storedJointAccount.membersCount,
                signersCount: storedJointAccount.threshold,
                address: storedJointAccount.address,
                status: storedJointAccount.status
            )

            return CommonJointAccountModel(
                cryptoAccount: cryptoAccount,
                jointAccountConfig: config,
                members: members,
                invites: invites
            )
        }
    }
}
