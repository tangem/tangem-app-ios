//
//  JointAccountCompositionFixture.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation
@testable import Tangem

/// The records a wallet holds for one joint account, and the real service that reads them back, so that a test checks
/// its subject against the composition the app would put together rather than one written out by hand.
enum JointAccountCompositionFixture {
    static let userWalletId = UserWalletId(value: Data(repeating: 0xAB, count: 32))
    static let derivationIdentity = CryptoAccountDerivationIdentity(derivationIndex: 1, type: .joint)

    /// The account's identifier with the case of every letter flipped: the endpoint spells it its own way, and every
    /// reader of these records has to find them regardless.
    static var caseFlippedCryptoAccountId: String {
        let identifier = CryptoAccountModelId(userWalletId: userWalletId, derivationIdentity: derivationIdentity).rawValue.hexString

        return String(identifier.map { $0.isUppercase ? Character($0.lowercased()) : Character($0.uppercased()) })
    }

    /// - Parameter inviteIds: Nil on a wallet that was handed no invites at all, which is anyone's but the creator's;
    /// empty on the creator's own wallet for an account created with every slot taken.
    static func makeMembersService(
        status: JointAccountStatus = .pending,
        membersCount: Int,
        members: [JointAccountMember],
        inviteIds: [String]?
    ) -> CommonJointAccountMembersService {
        let repository = JointAccountsRepositoryStub(
            jointAccounts: [storedAccount(status: status, membersCount: membersCount, members: members)],
            invites: invitesRecords(inviteIds: inviteIds)
        )

        return makeMembersService(repository: repository)
    }

    static func makeMembersService(repository: JointAccountsRepository) -> CommonJointAccountMembersService {
        CommonJointAccountMembersService(
            userWalletId: userWalletId,
            derivationIdentity: derivationIdentity,
            jointAccountsRepository: repository
        )
    }

    static func storedAccount(
        status: JointAccountStatus,
        membersCount: Int,
        members: [JointAccountMember]
    ) -> StoredJointAccount {
        StoredJointAccount(
            cryptoAccountId: caseFlippedCryptoAccountId,
            membersCount: membersCount,
            threshold: 2,
            status: status,
            members: members.map { member in
                StoredJointAccount.Member(
                    name: member.name,
                    address: member.address,
                    role: member.role == .creator ? .creator : .member,
                    inviteId: member.role.inviteId
                )
            }
        )
    }

    static func pendingOperationsRecord(operations: [JointAccountOperation]) -> StoredJointAccountPendingOperations {
        StoredJointAccountPendingOperations(cryptoAccountId: caseFlippedCryptoAccountId, operations: operations)
    }

    static func coinTransfer(id: String = "coin", status: JointAccountOperationStatus = .awaitingSignatures) -> JointAccountOperation {
        JointAccountOperation(
            id: id,
            chainId: 1,
            safeTransaction: SafeTransaction(
                to: "0x2b5ad9c1e7f40638b2c1a9d3e5f70241c6b8a91c",
                value: 1_000_000_000_000_000,
                data: Data(),
                operation: 0,
                safeTxGas: 0,
                baseGas: 100_000,
                gasPrice: 1_000_000_000,
                gasToken: SafeGasToken.coinGasTokenRawValue,
                refundReceiver: "0x7e5fb2c1a9d3e5f70241c6b8a91cd9c1e7f45bdf",
                nonce: 0
            ),
            status: status,
            initiator: "0x7e5fb2c1a9d3e5f70241c6b8a91cd9c1e7f45bdf",
            signatures: []
        )
    }

    private static func invitesRecords(inviteIds: [String]?) -> [StoredJointAccountInvites] {
        guard let inviteIds else {
            return []
        }

        return [
            StoredJointAccountInvites(
                cryptoAccountId: caseFlippedCryptoAccountId,
                invites: inviteIds.map(StoredJointAccountInvite.init(id:))
            ),
        ]
    }
}
